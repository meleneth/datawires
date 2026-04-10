class EditAffordance < ApplicationRecord
  extend Forwardable

  belongs_to :edit_document,
           class_name: "Document",
           inverse_of: :edit_affordance

  belongs_to :for_schema_document,
             class_name: "Document",
             inverse_of: :edit_affordances_for_schema


  def_delegators :edit_document, :head_revision
  def body
    head_revision&.body || {}
  end

  scope :for_schema, ->(document) { where(for_schema_document: document) }

  validates :title, presence: true, uniqueness: { scope: :for_schema_document_id }

  validate :for_schema_document_must_be_schema_document
  validate :edit_document_must_not_equal_schema_document

  private

  def for_schema_document_must_be_schema_document
    return unless for_schema_document
    return if for_schema_document.schema?

    errors.add(:for_schema_document, "must be a schema document")
  end

  def edit_document_must_not_equal_schema_document
    return if edit_document_id.blank? || for_schema_document_id.blank?
    return unless edit_document_id == for_schema_document_id

    errors.add(:edit_document, "must be a separate document")
  end
end
