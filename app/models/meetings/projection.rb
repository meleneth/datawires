# frozen_string_literal: true

module Meetings
  Projection = Data.define(:revision, :status, :opened_at, :adjourned_at, :attendance_actor_ids, :quorum) do
    def self.empty
      new(revision: 0, status: "scheduled", opened_at: nil, adjourned_at: nil, attendance_actor_ids: [], quorum: nil)
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
        attributes.merge!(status: "adjourned", adjourned_at: record.occurred_at)
      end
      self.class.new(**attributes)
    end
  end
end
