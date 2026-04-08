# frozen_string_literal: true

class RenderView < ApplicationRecord
  belongs_to :for_schema_document,
    class_name: "Document",
    inverse_of: :render_views_for_schema

  belongs_to :view_document,
    class_name: "Document",
    inverse_of: :render_view_definition,
    optional: false

  validates :name, presence: true, uniqueness: { scope: :for_schema_document_id }

  validate :for_schema_document_must_be_schema_document
  validate :view_document_must_not_equal_schema_document

  private

  def for_schema_document_must_be_schema_document
    return unless for_schema_document

    return if for_schema_document.schema?

    errors.add(:for_schema_document, "must be a schema document")
  end

  def view_document_must_not_equal_schema_document
    return if view_document_id.blank? || for_schema_document_id.blank?
    return unless view_document_id == for_schema_document_id

    errors.add(:view_document, "must be a separate document")
  end
end
