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

  def body
    head_revision&.body || {}
  end

  def screen
    body.fetch("screen", {})
  end

  def column_count
    count = screen["columns"]
    count.present? ? count.to_i : 12
  end

  def projected_rows(root_cursor)
    return default_projected_rows(root_cursor) if body["rows"].blank?

    Array(body["rows"]).map do |row_data|
      EditForms::ProjectedRow.new(
        cells: Array(row_data).filter_map { |cell_data| project_cell(root_cursor, cell_data) },
        column_count: column_count
      )
    end.reject(&:empty?)
  end

  def default_projected_rows(root_cursor)
    root_cursor.children.map do |child_cursor|
      EditForms::ProjectedRow.new(
        cells: [
          EditForms::ProjectedField.new(
            cursor: child_cursor,
            span: nil,
            widget: "auto",
            label: true
          )
        ],
        column_count: column_count
      )
    end
  end

  private

  def project_cell(root_cursor, cell_data)
    return project_commit_cell(cell_data) if commit_cell?(cell_data)
    return project_field_cell(root_cursor, cell_data) if field_cell?(cell_data)

    raise ArgumentError, "unsupported edit affordance cell: #{cell_data.inspect}"
  end

  def project_commit_cell(cell_data)
    EditForms::ProjectedCommit.new(
      span: cell_data["span"],
      message_mode: cell_data["message_mode"] || "hidden"
    )
  end

  def project_field_cell(root_cursor, cell_data)
    binding_data = cell_data.fetch("binding")
    cursor = cursor_for_binding(root_cursor, binding_data)
    return nil unless cursor

    EditForms::ProjectedField.new(
      cursor: cursor,
      span: cell_data["span"],
      widget: cell_data["widget"] || "auto",
      label: cell_data.key?("label") ? cell_data["label"] : true,
      item_rows: cell_data["item_rows"]
    )
  end

  def cursor_for_binding(root_cursor, binding_data)
    binding = EditForms::CellBinding.new(binding_data)

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

    return if schema_wrapper.document.schema?

    errors.add(:schema_wrapper, "must wrap a schema document")
  end

  def edit_document_must_not_equal_schema_document_body
    return if edit_document_id.blank? || schema_wrapper.blank?
    return if schema_wrapper.document_id.blank?
    return unless edit_document_id == schema_wrapper.document_id

    errors.add(:edit_document, "must be a separate document")
  end
end
