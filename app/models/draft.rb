# frozen_string_literal: true

class Draft < ApplicationRecord
  belongs_to :document, inverse_of: :drafts

  belongs_to :based_on_revision,
             class_name: "Revision",
             optional: true

  belongs_to :created_by,
             class_name: "User",
             optional: true

  scope :for_actor, ->(actor) { where(created_by: actor) }

  validate :body_must_be_json_object
  validate :base_must_be_same_document

  def is_json_schema?
    return false unless body.has_key? :$schema
    return false unless body.has_key? :$id
    true if body[:$schema] == "https://json-schema.org/draft/2020-12/schema"
  end

  private

  def body_must_be_json_object
    errors.add(:body, "must be a JSON object") unless body.is_a?(Hash)
  end

  def base_must_be_same_document
    return if based_on_revision.nil?
    return if based_on_revision.document_id == document_id

    errors.add(:based_on_revision, "must belong to the same document")
  end
end
