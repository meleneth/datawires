# frozen_string_literal: true

class DomainCommitDocument < ApplicationRecord
  belongs_to :domain_commit
  belongs_to :document
  belongs_to :revision

  validates :revision_hash, presence: true
  validates :document_id, uniqueness: { scope: :domain_commit_id }
end
