# frozen_string_literal: true

class QueryDefinition < ApplicationRecord
  belongs_to :domain
  belongs_to :query_document, class_name: "Document", inverse_of: :query_definition

  validates :key, presence: true, uniqueness: { scope: :domain_id }
  validate :document_must_share_domain
  validate :document_must_use_query_schema

  delegate :body, :head_revision, to: :query_document

  private

  def document_must_share_domain
    return if query_document.blank? || query_document.domain == domain

    errors.add(:query_document, "must belong to the query domain")
  end

  def document_must_use_query_schema
    return if query_document.blank? || query_document.schema_document&.key == Queries::Schema::KEY

    errors.add(:query_document, "must use the Datawires Query schema")
  end
end
