# frozen_string_literal: true

class SchemaWrapper < ApplicationRecord
  belongs_to :document, inverse_of: :schema_wrapper

  has_many :edit_affordances,
           inverse_of: :schema_wrapper,
           dependent: :destroy

  has_many :view_affordances,
           inverse_of: :schema_wrapper,
           dependent: :destroy

  delegate :key, :title, :domain, :head_revision, :body, to: :document

  validate :document_must_be_schema

  def conforming_documents
    document.instance_documents.with_head.order(:title, :key)
  end

  private

  def document_must_be_schema
    return if document&.schema?

    errors.add(:document, "must be a schema document")
  end
end
