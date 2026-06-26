# frozen_string_literal: true

require "forwardable"

class EditAffordance < ApplicationRecord
  extend Forwardable

  WIDTHS = %w[narrow medium large full].freeze

  belongs_to :schema_wrapper,
             class_name: "SchemaWrapper",
             inverse_of: :edit_affordances

  belongs_to :edit_document,
             class_name: "Document",
             inverse_of: :edit_affordance

  def_delegators :edit_document, :head_revision

  scope :for_schema, ->(schema_wrapper) { where(schema_wrapper: schema_wrapper) }

  validates :title,
            presence: true,
            uniqueness: { scope: :schema_wrapper_id }

  validate :schema_wrapper_must_wrap_schema_document
  validate :edit_document_must_not_equal_schema_document_body
  validate :edit_document_body_must_match_affordance_dsl

  def body
    EditAffordances::Versions.upgrade(head_revision&.body)
  end

  def screen
    body.fetch("screen", {})
  end

  def column_count
    count = screen["columns"]
    count.present? ? count.to_i : 12
  end

  def projection(root_cursor, mode: :runtime, screen_id: nil)
    build_projection(root_cursor, body, mode: mode.to_sym, screen_id: screen_id)
  rescue ArgumentError, KeyError => e
    raise if mode.to_sym == :authoring

    fallback_projection(root_cursor, e)
  end

  def projected_rows(root_cursor, screen_id: nil)
    projection(root_cursor, screen_id: screen_id).rows
  end

  private

  def build_projection(root_cursor, affordance_body, mode:, screen_id:)
    return generated_projection(root_cursor) if affordance_body["screens"].blank? && affordance_body["rows"].blank?

    diagnostics = []
    inventory = SchemaPaths::Inventory.new(root_cursor: root_cursor)
    screens = project_screens(
      root_cursor,
      affordance_body,
      inventory: inventory,
      mode: mode,
      diagnostics: diagnostics
    )
    start_screen_id = start_screen_id_for(affordance_body, screens, screen_id: screen_id)
    active_screen = screens.find { |screen| screen.id == start_screen_id } || screens.first
    rows = active_screen&.rows || []
    defaults = active_screen&.defaults || EditAffordances::Projection::Defaults.new(
      column_count: column_count_for(affordance_body),
      width: width_for(affordance_body)
    )

    EditAffordances::Projection.new(
      rows: rows,
      screens: screens,
      defaults: defaults,
      diagnostics: diagnostics,
      start_screen_id: start_screen_id
    )
  end

  def generated_projection(root_cursor)
    EditAffordances::Generated.new(schema_wrapper: schema_wrapper).projection(root_cursor)
  end

  def fallback_projection(root_cursor, exception)
    fallback = generated_projection(root_cursor)
    diagnostic = EditAffordances::Projection::Diagnostic.new(
      severity: "error",
      message: "Fell back to generated editor: #{exception.message}",
      cell_data: nil
    )

    EditAffordances::Projection.new(
      rows: fallback.rows,
      screens: fallback.screens,
      bindings: fallback.bindings,
      defaults: fallback.defaults,
      diagnostics: fallback.diagnostics + [ diagnostic ]
    )
  end

  def column_count_for(affordance_body)
    count = screen_config_for(affordance_body)["columns"]
    count.present? ? count.to_i : 12
  end

  def default_span_for(affordance_body)
    span = screen_config_for(affordance_body)["default_span"]
    span.present? ? span.to_i : column_count_for(affordance_body)
  end

  def screen_for(affordance_body)
    affordance_body.fetch("screen", {})
  end

  def screen_config_for(affordance_body)
    affordance_body["screen"].presence || affordance_body
  end

  def project_screens(root_cursor, affordance_body, inventory:, mode:, diagnostics:)
    screen_definitions = screen_definitions_for(affordance_body)
    subforms_by_id = subforms_by_id_for(affordance_body)
    screen_titles = screen_definitions.index_by { |screen_data| screen_data["id"] }.transform_values { |screen_data| screen_data["title"] }

    screen_definitions.filter_map do |screen_data|
      subform_data = subform_for_screen(screen_data, subforms_by_id)
      root_binding = root_binding_for_screen(screen_data, subform_data)
      path_variables = path_variables_for_screen(root_cursor, root_binding)
      screen_root_cursor = root_cursor_for_screen(root_cursor, root_binding, path_variables: path_variables)
      next unless screen_root_cursor

      column_count = column_count_for(screen_data)
      default_span = default_span_for(screen_data)
      width = width_for(screen_data, affordance_body: affordance_body)
      commit_mode = commit_mode_for(screen_data, affordance_body)
      relative_bindings = subform_data.present?
      rows = Array(rows_for_screen(screen_data, subform_data)).map do |row_data|
        EditAffordances::ProjectedRow.new(
          cells: project_row_cells(
            screen_root_cursor,
            row_data,
            inventory: inventory,
            default_span: default_span,
            screen_titles: screen_titles,
            path_variables: path_variables,
            commit_mode: commit_mode,
            relative_bindings: relative_bindings,
            mode: mode,
            diagnostics: diagnostics
          ),
          column_count: column_count
        )
      end.reject(&:empty?)

      EditAffordances::Projection::Screen.new(
        id: screen_data["id"],
        title: screen_data["title"],
        root_binding: root_binding,
        root_cursor: screen_root_cursor,
        rows: rows,
        defaults: EditAffordances::Projection::Defaults.new(column_count: column_count, width: width),
        commit_mode: commit_mode,
        width: width
      )
    end
  end

  def subforms_by_id_for(affordance_body)
    Array(affordance_body["subforms"]).select { |subform| subform.is_a?(Hash) }.index_by { |subform| subform["id"] }
  end

  def subform_for_screen(screen_data, subforms_by_id)
    subforms_by_id[screen_data["subform"]]
  end

  def screen_definitions_for(affordance_body)
    screens = affordance_body["screens"]
    return screens if screens.present?

    [
      affordance_body.merge(
        "id" => "main",
        "title" => screen_for(affordance_body)["title"]
      )
    ]
  end

  def root_binding_for_screen(screen_data, subform_data)
    screen_data["root_binding"].presence || subform_data&.fetch("root_binding", nil)
  end

  def rows_for_screen(screen_data, subform_data)
    subform_data&.fetch("rows", nil) || screen_data["rows"]
  end

  def root_cursor_for_screen(root_cursor, root_binding, path_variables:)
    return root_cursor if root_binding.blank?

    cursor_for_binding(root_cursor, root_binding, path_variables: path_variables)
  end

  def start_screen_id_for(affordance_body, screens, screen_id:)
    available_ids = screens.map(&:id)
    return screen_id if screen_id.present? && available_ids.include?(screen_id)

    affordance_body["start_screen"].presence || screens.first&.id
  end

  def commit_mode_for(screen_data, affordance_body)
    screen_config_for(screen_data)["commit_mode"].presence ||
      affordance_body["commit_mode"].presence ||
      screen_for(affordance_body)["commit_mode"].presence ||
      "review_screen"
  end

  def width_for(screen_data, affordance_body: nil)
    width = screen_data["width"].presence || affordance_body&.fetch("width", nil).presence || "large"
    WIDTHS.include?(width) ? width : "large"
  end

  def project_row_cells(root_cursor, row_data, inventory:, default_span:, screen_titles:, path_variables:, commit_mode:, relative_bindings:, mode:, diagnostics:)
    Array(row_data).filter_map do |cell_data|
      project_cell(
        root_cursor,
        cell_data,
        inventory: inventory,
        default_span: default_span,
        screen_titles: screen_titles,
        path_variables: path_variables,
        commit_mode: commit_mode,
        relative_bindings: relative_bindings
      )
    rescue ArgumentError, KeyError => e
      raise unless mode.to_sym == :authoring

      diagnostic = EditAffordances::Projection::Diagnostic.new(
        severity: "error",
        message: e.message,
        cell_data: cell_data
      )
      diagnostics << diagnostic
      EditAffordances::Cells::Invalid.new(
        cell_data: cell_data,
        diagnostic: diagnostic,
        span: invalid_cell_span(cell_data) || default_span
      )
    end
  end

  def invalid_cell_span(cell_data)
    cell_data["span"] if cell_data.respond_to?(:[])
  end

  def project_cell(root_cursor, cell_data, inventory:, default_span:, screen_titles:, path_variables:, commit_mode:, relative_bindings:)
    return project_commit_cell(cell_data, default_span: default_span, commit_mode: commit_mode) if commit_cell?(cell_data)
    return project_navigation_cell(cell_data, default_span: default_span, screen_titles: screen_titles) if navigation_cell?(cell_data)
    return project_field_cell(root_cursor, cell_data, inventory: inventory, default_span: default_span, path_variables: path_variables, relative: relative_bindings) if field_cell?(cell_data)

    raise ArgumentError, "unsupported edit affordance cell: #{cell_data.inspect}"
  end

  def project_commit_cell(cell_data, default_span:, commit_mode:)
    EditAffordances::Cells::Commit.new(
      span: cell_data["span"] || default_span,
      message_mode: cell_data["message_mode"] || "hidden",
      commit_mode: cell_data["commit_mode"].presence || commit_mode
    )
  end

  def project_navigation_cell(cell_data, default_span:, screen_titles:)
    target_screen_id = cell_data.fetch("target_screen")
    EditAffordances::Cells::Navigation.new(
      span: cell_data["span"] || default_span,
      target_screen_id: target_screen_id,
      label: cell_data["label"].presence || screen_titles[target_screen_id].presence || "Open"
    )
  end

  def project_field_cell(root_cursor, cell_data, inventory:, default_span:, path_variables:, relative:)
    binding_data = cell_data.fetch("binding")
    cursor = cursor_for_binding(root_cursor, binding_data, path_variables: path_variables, relative: relative)
    return nil unless cursor

    cell_class = cell_data["widget"] == "array" || cursor.array? ? EditAffordances::Cells::Array : EditAffordances::Cells::Field
    cell_args = {
      cursor: cursor,
      span: cell_data["span"] || default_span,
      widget: cell_data["widget"] || "auto",
      label: cell_data.key?("label") ? cell_data["label"] : true,
      item_rows: cell_data["item_rows"],
      help: cell_data["help"],
      placeholder: cell_data["placeholder"],
      display: cell_data["display"],
      schema_entry: inventory.entry_for(cursor)
    }
    cell_args[:reference] = cell_data["reference"] if cell_class == EditAffordances::Cells::Field
    cell_args[:collection] = cell_data["collection"] if cell_class == EditAffordances::Cells::Array

    cell_class.new(**cell_args)
  end

  def cursor_for_binding(root_cursor, binding_data, path_variables: {}, relative: false)
    binding = EditAffordances::CellBinding.new(binding_data)

    case binding.kind
    when "document_ptr"
      cursor_for_ptr(root_cursor, substitute_path_variables(binding.ptr, path_variables), relative: relative)
    else
      raise ArgumentError, "unsupported binding kind: #{binding.kind.inspect}"
    end
  end

  def path_variables_for_screen(root_cursor, root_binding)
    return {} if root_binding.blank?

    binding = EditAffordances::CellBinding.new(root_binding)
    return {} unless binding.document_ptr?

    variables_for_ptr(binding.ptr, root_cursor.path.to_s)
  rescue EditAffordances::CellBinding::UnsupportedBindingKindError
    {}
  end

  def variables_for_ptr(pattern_ptr, current_ptr)
    pattern_tokens = Documents::Path.new(pattern_ptr).tokens
    current_tokens = Documents::Path.new(current_ptr).tokens
    return {} unless pattern_tokens.length == current_tokens.length

    pattern_tokens.zip(current_tokens).each_with_object({}) do |(pattern_token, current_token), variables|
      if path_variable?(pattern_token)
        variables[pattern_token.delete_prefix(":")] = current_token
      elsif pattern_token != current_token
        return {}
      end
    end
  rescue Documents::Path::InvalidPathError
    {}
  end

  def substitute_path_variables(ptr, variables)
    return ptr if variables.blank?

    path = Documents::Path.new(ptr)
    tokens = path.tokens.map do |token|
      next variables.fetch(token.delete_prefix(":"), token) if path_variable?(token)

      token
    end
    JsonPtr::Pointer.from_unescaped(tokens).to_s
  rescue Documents::Path::InvalidPathError
    ptr
  end

  def path_variable?(token)
    token.to_s.start_with?(":") && token.to_s.length > 1
  end

  def cursor_for_ptr(root_cursor, ptr, relative: false)
    candidate_path = Documents::Path.new(relative ? absolute_ptr_for(root_cursor.path, ptr) : ptr)
    return nil unless within_root?(root_cursor.path, candidate_path)

    candidate_cursor = root_cursor.at(candidate_path)
    return nil unless candidate_cursor.resolves?

    candidate_cursor
  rescue Documents::Path::InvalidPathError, ArgumentError
    nil
  end

  def absolute_ptr_for(root_path, ptr)
    relative_path = Documents::Path.new(ptr)
    JsonPtr::Pointer.from_unescaped(root_path.tokens + relative_path.tokens).to_s
  end

  def within_root?(root_path, candidate_path)
    root_tokens = root_path.tokens
    candidate_tokens = candidate_path.tokens

    candidate_tokens.first(root_tokens.length) == root_tokens
  end

  def commit_cell?(cell_data)
    cell_data.is_a?(Hash) && cell_data["kind"] == "commit"
  end

  def navigation_cell?(cell_data)
    cell_data.is_a?(Hash) && cell_data["kind"] == "navigation"
  end

  def field_cell?(cell_data)
    cell_data.is_a?(Hash) && cell_data.key?("binding")
  end

  def schema_wrapper_must_wrap_schema_document
    return unless schema_wrapper&.document

    return if schema_wrapper.document.supported_schema?

    errors.add(:schema_wrapper, "must wrap a supported schema document")
  end

  def edit_document_must_not_equal_schema_document_body
    return if edit_document_id.blank? || schema_wrapper.blank?
    return if schema_wrapper.document_id.blank?
    return unless edit_document_id == schema_wrapper.document_id

    errors.add(:edit_document, "must be a separate document")
  end

  def edit_document_body_must_match_affordance_dsl
    return if edit_document.blank?

    validator = EditAffordances::BodyValidator.new(head_revision&.body)
    return if validator.valid?

    validator.errors.each do |message|
      errors.add(:edit_document, message)
    end
  end
end
