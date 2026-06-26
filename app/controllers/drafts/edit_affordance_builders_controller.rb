# frozen_string_literal: true

module Drafts
  class EditAffordanceBuildersController < ApplicationController
    BUILDER_SPAN_RANGE = (1..12).freeze
    COMMIT_MODES = %w[review_screen immediate].freeze
    DEFAULT_FIELD_SPAN = 3
    MESSAGE_MODES = %w[hidden inline_optional inline_required].freeze
    WIDTHS = %w[narrow medium large full].freeze
    WIDGETS = %w[auto text textarea number checkbox select array base64_image].freeze

    before_action :load_context

    def show
      @tab = tab_param
    end

    def row
      @tab = "row"
      @row_index = row_index_param
      @row = row_at!(@row_index)
      render :show
    end

    def cell
      @tab = "cell"
      @row_index = row_index_param
      @cell_index = cell_index_param
      @row = row_at!(@row_index)
      @cell = cell_at!(@row, @cell_index)
      render :show
    end

    def add_row
      body = deep_dup_json(@draft.body)
      builder_rows_for(body) << []
      @draft.update!(body: body)

      redirect_to builder_path,
        notice: "Row added."
    end

    def add_field
      @draft.update!(body: body_with_added_field)

      redirect_to builder_path,
        notice: "Field added."
    rescue ArgumentError => e
      redirect_to builder_path,
        alert: e.message
    end

    def add_navigation
      @draft.update!(body: body_with_added_navigation)

      redirect_to builder_path,
        notice: "Navigation added."
    rescue ArgumentError => e
      redirect_to builder_path,
        alert: e.message
    end

    def add_commit
      @draft.update!(body: body_with_added_commit)

      redirect_to builder_path,
        notice: "Commit added."
    rescue ArgumentError => e
      redirect_to builder_path,
        alert: e.message
    end

    def add_screen
      body = deep_dup_json(@draft.body)
      screen = screen_from_params(body)
      ensure_screens(body) << screen
      @draft.update!(body: body)

      redirect_to builder_path(screen_id: screen.fetch("id")),
        notice: "Screen added."
    rescue ArgumentError => e
      redirect_to builder_path,
        alert: e.message
    end

    def add_subform
      body = deep_dup_json(@draft.body)
      subform = subform_from_params(body)
      ensure_subforms(body) << subform
      @draft.update!(body: body)

      redirect_to builder_path,
        notice: "Subform added."
    rescue ArgumentError => e
      redirect_to builder_path,
        alert: e.message
    end

    def update_screen
      body = deep_dup_json(@draft.body)
      screen = builder_screen_for(body)
      if params.key?(:title)
        title = params[:title].presence
        title ? screen["title"] = title : screen.delete("title")
      end
      screen["width"] = params[:width].presence_in(WIDTHS) || "large"
      screen["default_span"] = normalized_span(params[:default_span])
      screen["columns"] = 12
      @draft.update!(body: body)

      redirect_to builder_path,
        notice: "Screen layout updated."
    end

    def update_raw
      @draft.update!(body: JSON.parse(params.require(:body_json)))

      redirect_to draft_edit_affordance_builder_path(@draft, tab: "raw"),
        notice: "Raw affordance JSON updated."
    rescue JSON::ParserError => e
      redirect_to draft_edit_affordance_builder_path(@draft, tab: "raw"),
        alert: "Invalid JSON: #{e.message}"
    end

    def destroy_affordance
      schema_wrapper = @schema_wrapper
      edit_document = @edit_affordance.edit_document

      ApplicationRecord.transaction do
        @edit_affordance.destroy!
        edit_document.reload
        edit_document.drafts.destroy_all
        edit_document.revisions.destroy_all
        edit_document.destroy!
      end

      redirect_to schema_path(schema_wrapper),
        notice: "Edit affordance deleted."
    end

    def delete_row
      body = deep_dup_json(@draft.body)
      rows = builder_rows_for(body)
      index = row_index_param
      row_at!(index, rows: rows)
      rows.delete_at(index)
      @draft.update!(body: body)

      redirect_to builder_path,
        notice: "Row deleted."
    end

    def move_row
      body = deep_dup_json(@draft.body)
      rows = builder_rows_for(body)
      row_index = row_index_param
      row_at!(row_index, rows: rows)
      target_index = target_row_index(row_index, params[:direction])
      unless target_index >= 0 && target_index < rows.length
        return redirect_to builder_path,
          alert: "Row cannot be moved #{params[:direction]}."
      end

      rows[row_index], rows[target_index] = rows[target_index], rows[row_index]
      @draft.update!(body: body)

      redirect_to builder_path,
        notice: "Row moved."
    end

    def delete_cell
      body = deep_dup_json(@draft.body)
      rows = builder_rows_for(body)
      row_index = row_index_param
      cell_index = cell_index_param
      row = row_at!(row_index, rows: rows)
      cell_at!(row, cell_index)
      row.delete_at(cell_index)
      @draft.update!(body: body)

      redirect_to row_path(row_index),
        notice: "Field deleted."
    end

    def move_cell
      body = deep_dup_json(@draft.body)
      rows = builder_rows_for(body)
      row_index = row_index_param
      cell_index = cell_index_param
      row = row_at!(row_index, rows: rows)
      cell_at!(row, cell_index)
      target_index = target_cell_index(cell_index, params[:direction])
      unless target_index >= 0 && target_index < row.length
        return redirect_to row_path(row_index),
          alert: "Field cannot be moved #{params[:direction]}."
      end

      row[cell_index], row[target_index] = row[target_index], row[cell_index]
      @draft.update!(body: body)

      redirect_to row_path(row_index),
        notice: "Field moved."
    end

    def update_cell
      body = deep_dup_json(@draft.body)
      rows = builder_rows_for(body)
      row_index = row_index_param
      cell_index = cell_index_param
      row = row_at!(row_index, rows: rows)
      cell = cell_at!(row, cell_index)
      row[cell_index] = updated_cell_from_params(cell)
      @draft.update!(body: body)

      redirect_to cell_path(row_index, cell_index),
        notice: "Cell updated."
    rescue ArgumentError => e
      redirect_to cell_path(params[:row_index], params[:cell_index]),
        alert: e.message
    end

    private

    def load_context
      @draft = Draft.includes(document: :edit_affordance).find(params[:draft_id])
      @edit_affordance = @draft.document.edit_affordance
      raise ActiveRecord::RecordNotFound, "draft is not an edit affordance draft" unless @edit_affordance

      @schema_wrapper = @edit_affordance.schema_wrapper
      @schema_document = @schema_wrapper.document
      @domain = @schema_wrapper.domain
      @field_entries = field_entries
      @diagnostics = EditAffordances::BodyValidator.new(@draft.body).errors
      @preview_projection = preview_projection
      @screen_ids = screen_ids
      @subform_ids = subform_ids
      @selected_screen = current_builder_screen
      @screen_id = @selected_screen&.fetch("id", nil) || "main"
      @active_subform = current_builder_subform
      @rows = current_builder_rows
      @screen_ids = screen_ids
      @builder_width_class = width_class_for(@selected_screen&.fetch("width", "large"))
    end

    def tab_param
      params[:tab].presence_in(%w[builder preview diagnostics raw]) || "builder"
    end

    def body_with_added_field
      body = deep_dup_json(@draft.body)
      target_row(body) << field_cell_from_params
      body
    end

    def body_with_added_navigation
      body = deep_dup_json(@draft.body)
      target_row(body) << navigation_cell_from_params
      body
    end

    def body_with_added_commit
      body = deep_dup_json(@draft.body)
      target_row(body) << commit_cell_from_params
      body
    end

    def ensure_main_screen(body)
      body["version"] ||= 1
      body["start_screen"] ||= "main"
      body["commit_mode"] ||= "review_screen"
      ensure_subforms(body)
      screens = ensure_screens(body)
      main_screen = screens.find { |screen| screen.is_a?(Hash) && screen["id"] == "main" }
      return main_screen.tap { |screen| screen["rows"] = Array(screen["rows"]) } if main_screen

      screens << {
        "id" => "main",
        "title" => "Main",
        "columns" => 12,
        "default_span" => DEFAULT_FIELD_SPAN,
        "width" => "large",
        "rows" => []
      }
      screens.last
    end

    def ensure_screens(body)
      body["screens"] = Array(body["screens"])
    end

    def ensure_subforms(body)
      body["subforms"] = Array(body["subforms"])
    end

    def field_cell_from_params
      ptr = params.require(:ptr)
      widget = params[:widget].presence_in(WIDGETS) || "auto"
      field_entry = @field_entries.find { |entry| entry.ptr == ptr }
      cell = {
        "binding" => {
          "kind" => "document_ptr",
          "ptr" => ptr
        },
        "widget" => widget,
        "label" => ActiveModel::Type::Boolean.new.cast(params[:label]) == true
      }
      cell["span"] = normalized_span(params[:span])
      cell["help"] = params[:help] if params[:help].present?
      cell["placeholder"] = params[:placeholder] if params[:placeholder].present?
      cell["collection"] = collection_config_from_params if field_entry&.array?
      cell
    end

    def navigation_cell_from_params
      target_screen = target_screen_param
      {
        "kind" => "navigation",
        "target_screen" => target_screen,
        "label" => params[:navigation_label].presence || target_screen.titleize,
        "span" => normalized_span(params[:navigation_span] || params[:span])
      }
    end

    def commit_cell_from_params
      {
        "kind" => "commit",
        "span" => normalized_span(params[:commit_span] || params[:span]),
        "message_mode" => params[:message_mode].presence_in(MESSAGE_MODES) || "inline_optional",
        "commit_mode" => params[:commit_mode].presence_in(COMMIT_MODES) || "review_screen"
      }
    end

    def updated_cell_from_params(cell)
      if field_cell?(cell)
        field_cell_from_params
      elsif navigation_cell?(cell)
        navigation_cell_from_params
      elsif commit_cell?(cell)
        commit_cell_from_params
      else
        raise ArgumentError, "Cell type is not supported by the structured editor."
      end
    end

    def target_row(body)
      rows = builder_rows_for(body)
      raise ArgumentError, "Add a row before adding fields." if rows.empty?

      selected_index = params[:row_index].presence || (rows.length - 1).to_s
      index = begin
        Integer(selected_index, 10)
      rescue ArgumentError
        raise ArgumentError, "Select an existing row before adding a field."
      end
      return rows[index] if index >= 0 && index < rows.length

      raise ArgumentError, "Select an existing row before adding a field."
    end

    def screen_from_params(body)
      ensure_main_screen(body)
      id = normalized_identifier(params[:new_screen_id], label: "Screen id")
      raise ArgumentError, "Screen id already exists." if screen_ids_for(body).include?(id)

      screen = {
        "id" => id,
        "title" => params[:new_screen_title].presence || id.titleize,
        "columns" => 12,
        "default_span" => normalized_span(params[:new_screen_default_span]),
        "width" => params[:new_screen_width].presence_in(WIDTHS) || "large"
      }
      root_ptr = params[:new_screen_root_ptr].presence
      screen["root_binding"] = { "kind" => "document_ptr", "ptr" => root_ptr } if root_ptr
      subform_id = params[:new_screen_subform].presence
      if subform_id
        raise ArgumentError, "Select an existing subform." unless subform_ids_for(body).include?(subform_id)

        screen["subform"] = subform_id
      else
        screen["rows"] = []
      end
      screen
    end

    def subform_from_params(body)
      ensure_main_screen(body)
      id = normalized_identifier(params[:new_subform_id], label: "Subform id")
      raise ArgumentError, "Subform id already exists." if subform_ids_for(body).include?(id)

      {
        "id" => id,
        "rows" => []
      }.tap do |subform|
        root_ptr = params[:new_subform_root_ptr].presence
        subform["root_binding"] = { "kind" => "document_ptr", "ptr" => root_ptr } if root_ptr
      end
    end

    def normalized_identifier(value, label:)
      id = value.to_s.strip
      raise ArgumentError, "#{label} is required." if id.blank?
      return id if id.match?(/\A[a-z][a-z0-9_-]*\z/)

      raise ArgumentError, "#{label} must start with a lowercase letter and use lowercase letters, numbers, dashes, or underscores."
    end

    def append_row(rows)
      rows << []
      rows.last
    end

    def normalized_span(raw_span)
      span = raw_span.presence&.to_i || DEFAULT_FIELD_SPAN
      span.clamp(BUILDER_SPAN_RANGE.begin, BUILDER_SPAN_RANGE.end)
    end

    def collection_config_from_params
      config = EditAffordances::Collection.default_config.merge(
        "presentation" => params[:collection_presentation].presence || EditAffordances::Collection::DEFAULT_PRESENTATION,
        "creation" => params[:collection_creation].presence || EditAffordances::Collection::DEFAULT_CREATION,
        "delete" => params[:collection_delete].presence || EditAffordances::Collection::DEFAULT_POLICY,
        "reorder" => params[:collection_reorder].presence || EditAffordances::Collection::DEFAULT_POLICY,
        "item_title" => collection_binding_from_params("item_title", default: EditAffordances::Collection::DEFAULT_TITLE_BINDING),
        "item_subtitle" => collection_binding_from_params("item_subtitle", default: EditAffordances::Collection::DEFAULT_SUBTITLE_BINDING)
      )
      config["item_screen"] = target_screen_param(param_name: :collection_item_screen, allow_blank: true) if params[:collection_item_screen].present?
      config
    end

    def collection_binding_from_params(prefix, default:)
      kind = params["#{prefix}_kind"].presence
      return default unless kind
      return { "kind" => "none" } if kind == "none"
      return { "kind" => "value_label" } if kind == "value_label"

      {
        "kind" => "property",
        "name" => params["#{prefix}_name"].presence || default["name"].presence || "name"
      }
    end

    def field_entries
      source = SchemaPreviewSource.new(schema_document: @schema_document, body: seeded_example_body)
      cursor = Documents::Cursor.new(source: source, path: "")
      collect_field_entries(SchemaPaths::Inventory.new(root_cursor: cursor), cursor)
    end

    def collect_field_entries(inventory, cursor)
      cursor.children.flat_map do |child|
        entry = inventory.entry_for(child)
        child.object? ? collect_field_entries(inventory, child) : [ entry ]
      end
    end

    def preview_projection
      source = SchemaPreviewSource.new(schema_document: @schema_document, body: seeded_example_body)
      cursor = Documents::Cursor.new(source: source, path: "")
      projection_affordance.projection(cursor, mode: :authoring)
    rescue ArgumentError, KeyError => e
      EditAffordances::Projection.new(
        rows: [],
        diagnostics: [
          EditAffordances::Projection::Diagnostic.new(
            severity: "error",
            message: e.message,
            cell_data: nil
          )
        ]
      )
    end

    def current_builder_screen
      ensure_main_screen(@draft.body)
      screens = Array(@draft.body["screens"]).select { |screen| screen.is_a?(Hash) }
      requested_id = params[:screen_id].presence || "main"
      screens.find { |screen| screen["id"] == requested_id } || screens.find { |screen| screen["id"] == "main" } || screens.first
    end

    def current_builder_subform
      subform_for_screen(@selected_screen, body: @draft.body)
    end

    def current_builder_rows
      target = @active_subform || @selected_screen
      return [] unless target

      target["rows"] = Array(target["rows"])
    end

    def screen_ids
      screen_ids_for(@draft.body)
    end

    def subform_ids
      subform_ids_for(@draft.body)
    end

    def screen_ids_for(body)
      Array(body["screens"]).filter_map do |screen|
        screen["id"] if screen.is_a?(Hash) && screen["id"].is_a?(String) && screen["id"].present?
      end
    end

    def subform_ids_for(body)
      Array(body["subforms"]).filter_map do |subform|
        subform["id"] if subform.is_a?(Hash) && subform["id"].is_a?(String) && subform["id"].present?
      end
    end

    def builder_screen_for(body)
      ensure_main_screen(body)
      screens = Array(body["screens"]).select { |screen| screen.is_a?(Hash) }
      requested_id = params[:screen_id].presence || @screen_id.presence || "main"
      screens.find { |screen| screen["id"] == requested_id } || screens.find { |screen| screen["id"] == "main" } || screens.first
    end

    def builder_rows_for(body)
      screen = builder_screen_for(body)
      target = subform_for_screen(screen, body: body) || screen
      target["rows"] = Array(target["rows"])
    end

    def subform_for_screen(screen, body:)
      return nil unless screen.is_a?(Hash) && screen["subform"].present?

      Array(body["subforms"]).find { |subform| subform.is_a?(Hash) && subform["id"] == screen["subform"] }
    end

    def row_index_param
      Integer(params.require(:row_index), 10)
    end

    def cell_index_param
      Integer(params.require(:cell_index), 10)
    end

    def row_at!(index, rows: @rows)
      return rows[index] if index >= 0 && index < rows.length && rows[index].is_a?(Array)

      raise ActiveRecord::RecordNotFound, "row not found"
    end

    def cell_at!(row, index)
      return row[index] if index >= 0 && index < row.length && row[index].is_a?(Hash)

      raise ActiveRecord::RecordNotFound, "field not found"
    end

    def target_screen_param(param_name: :target_screen, allow_blank: false)
      value = params[param_name].presence
      return nil if value.blank? && allow_blank
      raise ArgumentError, "Select an existing screen." if value.blank?
      return value if screen_ids.include?(value)

      raise ArgumentError, "Select an existing screen."
    end

    def field_cell?(cell)
      cell.is_a?(Hash) && cell.key?("binding")
    end

    def navigation_cell?(cell)
      cell.is_a?(Hash) && cell["kind"] == "navigation"
    end

    def commit_cell?(cell)
      cell.is_a?(Hash) && cell["kind"] == "commit"
    end

    def target_row_index(row_index, direction)
      case direction
      when "up"
        row_index - 1
      when "down"
        row_index + 1
      else
        row_index
      end
    end

    def target_cell_index(cell_index, direction)
      case direction
      when "left"
        cell_index - 1
      when "right"
        cell_index + 1
      else
        cell_index
      end
    end

    def width_class_for(width)
      case width
      when "narrow"
        "mx-auto w-full max-w-3xl"
      when "medium"
        "mx-auto w-full max-w-5xl"
      when "full"
        "w-full"
      else
        "mx-auto w-full max-w-[2560px]"
      end
    end

    def projection_affordance
      body = @draft.body
      @projection_affordance ||= EditAffordance.new(
        schema_wrapper: @schema_wrapper,
        edit_document: @draft.document
      ).tap do |affordance|
        affordance.define_singleton_method(:body) { body }
      end
    end

    def seeded_example_body
      Documents::SeedValue.for(@schema_wrapper.body)
    end

    def deep_dup_json(value)
      Marshal.load(Marshal.dump(value))
    end

    def builder_path(tab: "builder", screen_id: @screen_id)
      options = { tab: tab }
      options[:screen_id] = screen_id if screen_id.present? && screen_id != "main"
      draft_edit_affordance_builder_path(@draft, options)
    end

    def row_path(row_index, screen_id: @screen_id)
      options = { row_index: row_index }
      options[:screen_id] = screen_id if screen_id.present? && screen_id != "main"
      row_draft_edit_affordance_builder_path(@draft, options)
    end

    def cell_path(row_index, cell_index, screen_id: @screen_id)
      options = { row_index: row_index, cell_index: cell_index }
      options[:screen_id] = screen_id if screen_id.present? && screen_id != "main"
      cell_draft_edit_affordance_builder_path(@draft, options)
    end

    class SchemaPreviewSource
      attr_reader :schema_document, :body

      def initialize(schema_document:, body:)
        @schema_document = schema_document
        @body = body
      end

      def schema_document?
        false
      end
    end
  end
end
