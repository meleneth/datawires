# frozen_string_literal: true

module Meetings
  Projection = Data.define(
    :revision,
    :status,
    :opened_at,
    :adjourned_at,
    :attendance_actor_ids,
    :quorum,
    :recognition_requests,
    :floor_holder_id,
    :floor_reason,
    :floor_history,
    :scheduled_proposals,
    :pending_question_stack
  ) do
    def self.empty
      new(
        revision: 0,
        status: "scheduled",
        opened_at: nil,
        adjourned_at: nil,
        attendance_actor_ids: [],
        quorum: nil,
        recognition_requests: [],
        floor_holder_id: nil,
        floor_reason: nil,
        floor_history: [],
        scheduled_proposals: [],
        pending_question_stack: []
      )
    end

    def self.rebuild(records)
      records.reduce(empty) { |projection, record| projection.apply(record) }
    end

    def apply(record)
      attributes = to_h.merge(revision: record.sequence)
      case record.event_type
      when "MeetingOpened"
        attributes.merge!(status: "open", opened_at: record.occurred_at)
      when "AttendanceEstablished"
        attributes.merge!(attendance_actor_ids: Array(record.payload["actor_ids"]).freeze)
      when "QuorumEstablished"
        attributes.merge!(quorum: record.payload.deep_dup.freeze)
      when "MeetingAdjourned"
        history = floor_history.deep_dup
        if floor_holder_id
          history.last&.merge!(
            "ended_at" => record.occurred_at.iso8601,
            "end_reason" => "meeting_adjourned"
          )
        end
        attributes.merge!(
          status: "adjourned",
          adjourned_at: record.occurred_at,
          recognition_requests: [],
          floor_holder_id: nil,
          floor_reason: nil,
          floor_history: UuidTools.deep_freeze(history)
        )
      when "RecognitionRequested"
        requests = recognition_requests + [
          {
            "actor_id" => record.payload.fetch("actor_id"),
            "reason" => record.payload["reason"],
            "requested_at" => record.occurred_at.iso8601
          }.compact
        ]
        attributes.merge!(recognition_requests: UuidTools.deep_freeze(requests))
      when "MemberRecognized"
        actor_id = record.payload.fetch("actor_id")
        history = floor_history + [
          {
            "actor_id" => actor_id,
            "reason" => record.payload["reason"],
            "granted_at" => record.occurred_at.iso8601
          }.compact
        ]
        attributes.merge!(
          recognition_requests: recognition_requests.reject { |request| request["actor_id"] == actor_id }.freeze,
          floor_holder_id: actor_id,
          floor_reason: record.payload["reason"],
          floor_history: UuidTools.deep_freeze(history)
        )
      when "FloorRelinquished"
        history = floor_history.deep_dup
        history.last&.merge!(
          "ended_at" => record.occurred_at.iso8601,
          "end_reason" => record.payload["reason"].presence || "relinquished"
        )
        attributes.merge!(
          floor_holder_id: nil,
          floor_reason: nil,
          floor_history: UuidTools.deep_freeze(history)
        )
      when "ProposalScheduled"
        scheduled = scheduled_proposals + [
          {
            "proposal_id" => record.payload.fetch("proposal_id"),
            "proposal_revision_id" => record.payload.fetch("proposal_revision_id"),
            "scheduled_by_id" => record.actor_id
          }
        ]
        attributes.merge!(scheduled_proposals: UuidTools.deep_freeze(scheduled))
      end
      self.class.new(**attributes)
    end
  end
end
