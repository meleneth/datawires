# frozen_string_literal: true

class Document < ApplicationRecord
  JSON_SCHEMA_2020_12 = "https://json-schema.org/draft/2020-12/schema"

  belongs_to :domain

  belongs_to :head_revision,
             class_name: "Revision",
             optional: true,
             inverse_of: :head_for_documents

  has_many :revisions,
           -> { order(created_at: :asc) },
           dependent: :restrict_with_exception,
           inverse_of: :document

  has_many :drafts,
           dependent: :destroy,
           inverse_of: :document

  validates :key, presence: true, uniqueness: { scope: :domain_id }

  scope :with_head, -> { joins(:head_revision) }

  scope :schemas, -> {
          joins(:head_revision)
            .where("revisions.body @> ?", { "$schema" => JSON_SCHEMA_2020_12 }.to_json)
        }

  def to_param
    key
  end

  def draft_for(actor: nil)
    drafts.find_or_create_by!(created_by: actor) do |d|
      d.based_on_revision = head_revision
      d.body = body
    end
  end

  def body
    head_revision&.body || {}
  end

  def schema_document?
    body.is_a?(Hash) && body["$schema"].present?
  end
end
