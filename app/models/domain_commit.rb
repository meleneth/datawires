# frozen_string_literal: true

class DomainCommit < ApplicationRecord
  belongs_to :domain
  belongs_to :parent_domain_commit,
             class_name: "DomainCommit",
             optional: true
  belongs_to :created_by,
             class_name: "User",
             optional: true

  has_many :domain_commit_documents,
           dependent: :destroy,
           inverse_of: :domain_commit

  validates :state_hash, presence: true, uniqueness: { scope: :domain_id }
end
