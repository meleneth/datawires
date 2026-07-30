# frozen_string_literal: true

module Meetings
  module DefaultPolicy
    NAME = "Datawires Meeting Lifecycle"

    def self.command(capability, event_type, statuses, payload = {})
      {
        "capability" => capability,
        "allowed_statuses" => statuses,
        "event_type" => event_type,
        "event_version" => 1,
        "payload" => payload
      }
    end
    private_class_method :command

    BODY = {
      "version" => 1,
      "name" => NAME,
      "commands" => {
        "open_meeting" => command("open_meeting", "MeetingOpened", %w[scheduled]),
        "establish_attendance" => command("chair_action", "AttendanceEstablished", %w[open], "actor_ids" => "array"),
        "establish_quorum" => command("chair_action", "QuorumEstablished", %w[open], "present" => "boolean"),
        "adjourn_meeting" => command("chair_action", "MeetingAdjourned", %w[open]),
        "request_recognition" => command("request_recognition", "RecognitionRequested", %w[open]),
        "recognize_member" => command("chair_action", "MemberRecognized", %w[open], "actor_id" => "uuid"),
        "relinquish_floor" => command("request_recognition", "FloorRelinquished", %w[open]),
        "schedule_proposal" => command("schedule_proposal", "ProposalScheduled", %w[scheduled open], "proposal_id" => "uuid")
      }
    }.freeze
  end
end
