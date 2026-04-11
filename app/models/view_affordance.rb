# frozen_string_literal: true

require "forwardable"

class ViewAffordance < ApplicationRecord
  extend Forwardable

  belongs_to :for_schema_document,
             class_name: "SchemaDocument",
             inverse_of: :view_affordances

  belongs_to :view_document,
             class_name: "Document",
             inverse_of: :view_affordance

  def_delegators :view_document, :head_revision

  scope :for_schema, ->(schema_document) { where(for_schema_document: schema_document) }

  validates :title,
            presence: true,
            uniqueness: { scope: :for_schema_document_id }

  validate :for_schema_document_must_wrap_schema_document
  validate :view_document_must_not_equal_schema_document_body

  def body
    head_revision&.body || {}
  end

  private

  def for_schema_document_must_wrap_schema_document
    return unless for_schema_document&.document

    return if for_schema_document.document.schema?

    errors.add(:for_schema_document, "must wrap a schema document")
  end

  def view_document_must_not_equal_schema_document_body
    return if view_document_id.blank? || for_schema_document.blank?
    return if for_schema_document.document_id.blank?
    return unless view_document_id == for_schema_document.document_id

    errors.add(:view_document, "must be a separate document")
  end
end
