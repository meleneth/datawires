# frozen_string_literal: true

class Document < ApplicationRecord
  JSON_SCHEMA_2020_12 = "https://json-schema.org/draft/2020-12/schema"
  JSON_SCHEMA_MARKER = { "$schema" => JSON_SCHEMA_2020_12 }.freeze

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

  has_many :edit_affordances_for_schema,
           class_name: "EditAffordance",
           foreign_key: :for_schema_document_id,
           inverse_of: :for_schema_document,
           dependent: :destroy

  has_one :edit_affordance_definition,
          class_name: "EditAffordance",
          foreign_key: :affordance_document_id,
          inverse_of: :affordance_document,
          dependent: :restrict_with_exception

  has_many :render_views_for_schema,
           class_name: "RenderView",
           foreign_key: :for_schema_document_id,
           inverse_of: :for_schema_document,
           dependent: :destroy

  has_one :render_view_definition,
          class_name: "RenderView",
          foreign_key: :view_document_id,
          inverse_of: :view_document,
          dependent: :restrict_with_exception

  validates :key, presence: true, uniqueness: { scope: :domain_id }
  validate :schema_document_must_be_a_schema, if: -> { schema_document_id.present? }

  scope :with_head, -> { joins(:head_revision) }

  scope :schemas, -> {
    joins(:head_revision)
      .where("revisions.body @> ?", JSON_SCHEMA_MARKER.to_json)
  }

  scope :non_schemas, -> {
    left_joins(:head_revision)
      .where("revisions.id IS NULL OR NOT (revisions.body @> ?)", JSON_SCHEMA_MARKER.to_json)
  }

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
    body.is_a?(Hash) && body["$schema"] == JSON_SCHEMA_2020_12
  end

  alias schema_document? schema?

  private

  def schema_document_must_be_a_schema
    return if schema_document&.schema?

    errors.add(:schema_document, "must reference a schema document")
  end
end
