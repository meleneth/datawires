class Domain < ApplicationRecord
  has_many :event_streams, dependent: :restrict_with_exception
  has_many :documents, dependent: :restrict_with_exception
  has_many :domain_commits, dependent: :restrict_with_exception
  has_one :project_affordance, dependent: :destroy, inverse_of: :domain

  belongs_to :owner,
             class_name: "User",
             optional: true,
             inverse_of: :owned_domains

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

  scope :active, -> { where(archived_at: nil) }
  scope :publicly_visible, -> { where(public: true) }
  scope :owned_by, ->(user) { where(owner: user) }
  scope :visible_to, ->(user) {
    legacy_visible = active.where(owner_id: nil)
    publicly_visible = where(public: true).or(legacy_visible)

    user ? active.merge(publicly_visible.or(where(owner: user))) : active.merge(publicly_visible)
  }

  def archive!
    update!(archived_at: Time.current)
  end

  def archived?
    archived_at.present?
  end

  def private?
    !public?
  end

  def project?
    project_affordance.present?
  end

  def visible_to?(user)
    !archived? && (public? || owner.nil? || (user.present? && owner == user))
  end

  def open_drafts
    Draft.joins(:document)
      .where(documents: { domain_id: id })
      .includes(:document)
  end
end
