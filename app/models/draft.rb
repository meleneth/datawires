# frozen_string_literal: true

class Draft < ApplicationRecord
  belongs_to :document, inverse_of: :drafts

  belongs_to :based_on_revision,
             class_name: "Revision",
             optional: true

  belongs_to :created_by,
             class_name: "User"

  delegate :domain, :schema_document, :schema_document?, to: :document
  after_commit :broadcast_review_update, on: %i[create update]

  scope :for_actor, ->(actor) { where(created_by: actor) }

  validate :body_must_be_json_object
  validate :base_must_be_same_document

  def is_json_schema?
    return false unless body.has_key? "$schema"
    return false unless body.has_key? "$id"
    true if body["$schema"] == "https://json-schema.org/draft/2020-12/schema"
  end

  def schema_document?
    is_json_schema?
  end

  def review_stream_name
    "draft:#{id}:review"
  end

  def review_dom_id
    ActionView::RecordIdentifier.dom_id(self, :review)
  end

  def editor_dom_id_for(path)
    path = path.is_a?(Documents::Path) ? path : Documents::Path.new(path)
    suffix = path.document_ptr.to_s.gsub(/[^a-zA-Z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
    "editor_#{suffix.presence || "root"}"
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

  def broadcast_review_update
    broadcast_update_to(
      review_stream_name,
      target: review_dom_id,
      partial: "drafts/review",
      locals: {
        draft: self,
        diff_rows: Documents::Diff.rows(
          before: based_on_revision&.body,
          after: body
        )
      }
    )
  end
end
