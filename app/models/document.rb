# frozen_string_literal: true

class Document < ApplicationRecord
  JSON_SCHEMA_2020_12 = "https://json-schema.org/draft/2020-12/schema"

  belongs_to :domain

  belongs_to :head_revision,
             class_name: "Revision",
             optional: true,
             inverse_of: :head_for_documents

  belongs_to :schema_document,
             class_name: "Document",
             optional: true,
             inverse_of: :instance_documents

  has_many :revisions,
           -> { order(created_at: :asc) },
           dependent: :restrict_with_exception,
           inverse_of: :document

  has_many :drafts,
           dependent: :destroy,
           inverse_of: :document

  has_many :instance_documents,
           class_name: "Document",
           foreign_key: :schema_document_id,
           inverse_of: :schema_document

  has_one :view_affordance,
        class_name: "ViewAffordance",
        foreign_key: :view_document_id,
        inverse_of: :view_document,
        dependent: :restrict_with_exception

  has_one :edit_affordance,
          class_name: "EditAffordance",
          foreign_key: :edit_document_id,
          inverse_of: :edit_document,
          dependent: :restrict_with_exception

  has_one :external_document, dependent: :destroy, inverse_of: :document

  has_one :schema_wrapper,
        class_name: "SchemaWrapper",
        dependent: :destroy,
        inverse_of: :document

  validates :key, presence: true, uniqueness: { scope: :domain_id }
  validate :schema_document_must_be_schema_backed, if: -> { schema_document_id.present? }

  scope :with_head, -> { joins(:head_revision) }

  scope :schemas, lambda {
    joins(:head_revision)
      .where("revisions.body ? '$schema'")
  }

  scope :non_schemas, lambda {
    left_joins(:head_revision)
      .where("revisions.id IS NULL OR NOT (revisions.body ? '$schema')")
  }

  def edit_affordances
    schema_record&.edit_affordances || EditAffordance.none
  end

  def schema_record
    schema_document&.schema_wrapper
  end

  def edit_affordances_for_schema
    schema_record&.edit_affordances || EditAffordance.none
  end

  def to_param
    id
  end

  def draft_for(actor: nil)
    drafts.find_or_create_by!(created_by: actor) do |draft|
      draft.based_on_revision = head_revision
      draft.body = body
    end
  end

  def body
    head_revision&.body || {}
  end

  def schema?
    body.is_a?(Hash) && body["$schema"].is_a?(String) && body["$schema"].present?
  end

  alias schema_document? schema?

  private

  def schema_document_must_be_schema_backed
    return if schema_document.blank?
    return if schema_document == self && schema?
    return if schema_document.schema?

    errors.add(:schema_document, "must reference a schema document")
  end
end
