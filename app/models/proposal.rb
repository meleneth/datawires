# frozen_string_literal: true

class Proposal < ApplicationRecord
  belongs_to :proposal_document, class_name: "Document"
  belongs_to :body
  belongs_to :submitted_revision, class_name: "Revision"
  belongs_to :submitted_by, class_name: "User"

  validate :lineage_must_be_consistent

  private

  def lineage_must_be_consistent
    return if proposal_document.blank? || body.blank? || submitted_revision.blank?

    errors.add(:proposal_document, "must use the Proposal schema") unless proposal_document.schema_document&.key == Proposals::Schema::KEY
    errors.add(:proposal_document, "must share the Body domain") unless proposal_document.domain == body.domain
    errors.add(:submitted_revision, "must belong to the Proposal document") unless submitted_revision.document == proposal_document
  end
end
