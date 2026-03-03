# frozen_string_literal: true

class Revision < ApplicationRecord
  belongs_to :document, inverse_of: :revisions

  belongs_to :parent_revision,
             class_name: "Revision",
             optional: true,
             inverse_of: :child_revisions

  has_many :child_revisions,
           class_name: "Revision",
           foreign_key: :parent_revision_id,
           dependent: :nullify,
           inverse_of: :parent_revision

  has_many :head_for_documents,
           class_name: "Document",
           foreign_key: :head_revision_id,
           dependent: :nullify,
           inverse_of: :head_revision

  belongs_to :created_by,
             class_name: "User",
             optional: true

  validate :body_must_be_json_object
  validate :parent_must_be_same_document

  # Treat revisions as immutable history nodes.
  before_update :prevent_mutation

  private

  def body_must_be_json_object
    unless body.is_a?(Hash)
      errors.add(:body, "must be a JSON object")
    end
  end

  def prevent_mutation
    raise ActiveRecord::ReadOnlyRecord, "Revisions are immutable"
  end

  def parent_must_be_same_document
    return if parent_revision.nil?
    return if parent_revision.document_id == document_id

    errors.add(:parent_revision, "must belong to the same document")
  end
end
