# frozen_string_literal: true

require "forwardable"

class ViewAffordance < ApplicationRecord
  extend Forwardable

  belongs_to :schema_wrapper,
             class_name: "SchemaWrapper",
             inverse_of: :view_affordances

  belongs_to :view_document,
             class_name: "Document",
             inverse_of: :view_affordance

  def_delegators :view_document, :head_revision

  scope :for_schema, ->(schema_wrapper) { where(schema_wrapper: schema_wrapper) }

  validates :title,
            presence: true,
            uniqueness: { scope: :schema_wrapper_id }

  validate :schema_wrapper_must_wrap_schema_document
  validate :view_document_must_not_equal_schema_document_body

  def body
    head_revision&.body || {}
  end

  private

  def schema_wrapper_must_wrap_schema_document
    return unless schema_wrapper&.document

    return if schema_wrapper.document.schema?

    errors.add(:schema_wrapper, "must wrap a schema document")
  end

  def view_document_must_not_equal_schema_document_body
    return if view_document_id.blank? || schema_wrapper.blank?
    return if schema_wrapper.document_id.blank?
    return unless view_document_id == schema_wrapper.document_id

    errors.add(:view_document, "must be a separate document")
  end
end
