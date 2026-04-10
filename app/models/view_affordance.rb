# frozen_string_literal: true

class ViewAffordance < ApplicationRecord
  extend Forwardable

  belongs_to :for_schema_document,
    class_name: "Document",
    inverse_of: :view_affordances_for_schema

  belongs_to :view_document,
    class_name: "Document",
    inverse_of: :view_affordance

  def_delegators :view_document, :head_revision
  def_delegators :head_revision, :body

  scope :for_schema, ->(document) { where(for_schema_document: document) }

  validates :title, presence: true, uniqueness: { scope: :for_schema_document_id }

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
