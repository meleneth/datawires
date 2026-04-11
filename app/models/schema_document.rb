# frozen_string_literal: true

class SchemaDocument < ApplicationRecord
  belongs_to :document, inverse_of: :schema_document_record

  has_many :edit_affordances,
           foreign_key: :for_schema_document_id,
           inverse_of: :for_schema_document,
           dependent: :destroy

  has_many :view_affordances,
           foreign_key: :for_schema_document_id,
           inverse_of: :for_schema_document,
           dependent: :destroy

  delegate :key, :title, :domain, :head_revision, :body, to: :document

  validate :document_must_be_schema

  def conforming_documents
    document.instance_documents.order(:title, :key)
  end

  private

  def document_must_be_schema
    return if document&.schema?

    errors.add(:document, "must be a schema document")
  end
end
