# frozen_string_literal: true

require "forwardable"

class EditAffordance < ApplicationRecord
  extend Forwardable

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

  def projection(root_cursor, mode: :runtime)
    build_projection(root_cursor, body, mode: mode.to_sym)
  rescue ArgumentError, KeyError => e
    raise if mode.to_sym == :authoring

    fallback_projection(root_cursor, e)
  end

  def projected_rows(root_cursor)
    projection(root_cursor).rows
  end

  private

  def build_projection(root_cursor, affordance_body, mode:)
    return generated_projection(root_cursor) if affordance_body["rows"].blank?

    column_count = column_count_for(affordance_body)
    diagnostics = []
    rows = Array(affordance_body["rows"]).map do |row_data|
      EditAffordances::ProjectedRow.new(
        cells: project_row_cells(root_cursor, row_data, mode: mode, diagnostics: diagnostics),
        column_count: column_count
      )
    end.reject(&:empty?)

    EditAffordances::Projection.new(
      rows: rows,
      defaults: EditAffordances::Projection::Defaults.new(column_count: column_count),
      diagnostics: diagnostics
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
    count = screen_for(affordance_body)["columns"]
    count.present? ? count.to_i : 12
  end

  def screen_for(affordance_body)
    affordance_body.fetch("screen", {})
  end

  def project_row_cells(root_cursor, row_data, mode:, diagnostics:)
    Array(row_data).filter_map do |cell_data|
      project_cell(root_cursor, cell_data)
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
        span: invalid_cell_span(cell_data)
      )
    end
  end

  def invalid_cell_span(cell_data)
    cell_data["span"] if cell_data.respond_to?(:[])
  end

  def project_cell(root_cursor, cell_data)
    return project_commit_cell(cell_data) if commit_cell?(cell_data)
    return project_field_cell(root_cursor, cell_data) if field_cell?(cell_data)

    raise ArgumentError, "unsupported edit affordance cell: #{cell_data.inspect}"
  end

  def project_commit_cell(cell_data)
    EditAffordances::Cells::Commit.new(
      span: cell_data["span"],
      message_mode: cell_data["message_mode"] || "hidden"
    )
  end

  def project_field_cell(root_cursor, cell_data)
    binding_data = cell_data.fetch("binding")
    cursor = cursor_for_binding(root_cursor, binding_data)
    return nil unless cursor

    cell_class = cell_data["widget"] == "array" ? EditAffordances::Cells::Array : EditAffordances::Cells::Field

    cell_class.new(
      cursor: cursor,
      span: cell_data["span"],
      widget: cell_data["widget"] || "auto",
      label: cell_data.key?("label") ? cell_data["label"] : true,
      item_rows: cell_data["item_rows"]
    )
  end

  def cursor_for_binding(root_cursor, binding_data)
    binding = EditAffordances::CellBinding.new(binding_data)

    case binding.kind
    when "document_ptr"
      cursor_for_ptr(root_cursor, binding.ptr)
    else
      raise ArgumentError, "unsupported binding kind: #{binding.kind.inspect}"
    end
  end

  def cursor_for_ptr(root_cursor, ptr)
    candidate_path = Documents::Path.new(ptr)
    return nil unless within_root?(root_cursor.path, candidate_path)

    candidate_cursor = root_cursor.at(candidate_path)
    return nil unless candidate_cursor.resolves?

    candidate_cursor
  rescue Documents::Path::InvalidPathError, ArgumentError
    nil
  end

  def within_root?(root_path, candidate_path)
    root_tokens = root_path.tokens
    candidate_tokens = candidate_path.tokens

    candidate_tokens.first(root_tokens.length) == root_tokens
  end

  def commit_cell?(cell_data)
    cell_data.is_a?(Hash) && cell_data["kind"] == "commit"
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
