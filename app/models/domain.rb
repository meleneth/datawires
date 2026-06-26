class Domain < ApplicationRecord
  has_many :documents, dependent: :restrict_with_exception
  has_many :domain_commits, dependent: :restrict_with_exception

  belongs_to :head_domain_commit,
             class_name: "DomainCommit",
             optional: true

  has_many :schema_documents,
           -> { schemas },
           class_name: "Document",
           inverse_of: :domain

  has_many :non_schema_documents,
           -> { non_schemas },
           class_name: "Document",
           inverse_of: :domain

  validates :name, presence: true, uniqueness: true

  def open_drafts
    Draft.joins(:document)
      .where(documents: { domain_id: id })
      .includes(:document)
  end
end
