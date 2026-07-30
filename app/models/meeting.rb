# frozen_string_literal: true

class Meeting < ApplicationRecord
  belongs_to :meeting_document, class_name: "Document"
  belongs_to :body
  belongs_to :event_stream

  has_many :role_assignments, as: :scope, dependent: :destroy

  validate :resources_must_share_domain
  validate :stream_must_identify_meeting

  def projection
    Meetings::Projection.rebuild(event_stream.event_records)
  end

  private

  def resources_must_share_domain
    return if meeting_document.blank? || body.blank? || event_stream.blank?
    return if [ body.domain, event_stream.domain ].all? { |domain| domain == meeting_document.domain }

    errors.add(:base, "meeting resources must share a domain")
  end

  def stream_must_identify_meeting
    return if event_stream.blank?
    return if event_stream.stream_type == "meeting" && event_stream.subject_id == id

    errors.add(:event_stream, "must identify this meeting")
  end
end
