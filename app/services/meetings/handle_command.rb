# frozen_string_literal: true

module Meetings
  class HandleCommand
    class Rejected < StandardError; end

    COMMANDS = {
      "open_meeting" => {
        capability: :open_meeting,
        event: "MeetingOpened",
        allowed_statuses: %w[scheduled]
      },
      "establish_attendance" => {
        capability: :chair_action,
        event: "AttendanceEstablished",
        allowed_statuses: %w[open]
      },
      "establish_quorum" => {
        capability: :chair_action,
        event: "QuorumEstablished",
        allowed_statuses: %w[open]
      },
      "adjourn_meeting" => {
        capability: :chair_action,
        event: "MeetingAdjourned",
        allowed_statuses: %w[open]
      },
      "request_recognition" => {
        capability: :request_recognition,
        event: "RecognitionRequested",
        allowed_statuses: %w[open]
      },
      "recognize_member" => {
        capability: :chair_action,
        event: "MemberRecognized",
        allowed_statuses: %w[open]
      },
      "relinquish_floor" => {
        capability: :request_recognition,
        event: "FloorRelinquished",
        allowed_statuses: %w[open]
      },
      "schedule_proposal" => {
        capability: :schedule_proposal,
        event: "ProposalScheduled",
        allowed_statuses: %w[scheduled open]
      }
    }.freeze

    def self.call(meeting:, command:, authorizer: Authorization::Policy)
      new(meeting:, command:, authorizer:).call
    end

    def initialize(meeting:, command:, authorizer:)
      raise ArgumentError, "meeting must be a Meeting" unless meeting.is_a?(Meeting)
      raise ArgumentError, "command must be a Commands::Envelope" unless command.is_a?(Commands::Envelope)

      @meeting = meeting
      @command = command
      @authorizer = authorizer
    end

    def call
      definition = COMMANDS[command.type]
      raise Rejected, "Unsupported meeting command." unless definition

      decision = authorizer.call(
        actor: command.actor,
        action: definition.fetch(:capability),
        resource: { body: meeting.body, meeting:, at: command.timestamp }
      )
      raise Rejected, decision.reason unless decision.allowed?

      projection = meeting.projection
      unless definition.fetch(:allowed_statuses).include?(projection.status)
        raise Rejected, "#{command.type.humanize} is unavailable while the meeting is #{projection.status}."
      end

      validate_payload!
      validate_procedure!(projection)
      event = Events::Data.new(
        type: definition.fetch(:event),
        version: 1,
        payload: event_payload,
        provenance: { "authorization" => { "allowed" => true, "capability" => definition.fetch(:capability).to_s } }
      )
      EventStreams::Append.call(stream: meeting.event_stream, command:, events: [ event ])
    end

    private

    attr_reader :meeting, :command, :authorizer

    def validate_payload!
      if command.type == "establish_attendance" && !command.payload["actor_ids"].is_a?(Array)
        raise Rejected, "Attendance requires actor_ids."
      end
      return unless command.type == "establish_quorum"
      return if [ true, false ].include?(command.payload["present"])

      raise Rejected, "Quorum requires a boolean present value."
    end

    def validate_procedure!(projection)
      case command.type
      when "request_recognition"
        if projection.recognition_requests.any? { |request| request["actor_id"] == command.actor.user.id }
          raise Rejected, "The actor already has a recognition request."
        end
      when "recognize_member"
        actor_id = command.payload["actor_id"]
        raise Rejected, "Recognition requires actor_id." if actor_id.blank?
        raise Rejected, "Another actor currently holds the floor." if projection.floor_holder_id.present?
        unless projection.recognition_requests.any? { |request| request["actor_id"] == actor_id }
          raise Rejected, "The actor has not requested recognition."
        end
      when "relinquish_floor"
        unless projection.floor_holder_id == command.actor.user.id
          raise Rejected, "Only the current floor holder may relinquish the floor."
        end
      when "schedule_proposal"
        proposal = scheduled_proposal
        raise Rejected, "Proposal belongs to a different Body." unless proposal.body == meeting.body
        if projection.scheduled_proposals.any? { |entry| entry["proposal_id"] == proposal.id }
          raise Rejected, "Proposal is already scheduled."
        end
      end
    end

    def event_payload
      case command.type
      when "request_recognition"
        command.payload.merge("actor_id" => command.actor.user.id)
      when "relinquish_floor"
        command.payload.merge("actor_id" => command.actor.user.id)
      when "schedule_proposal"
        {
          "proposal_id" => scheduled_proposal.id,
          "proposal_revision_id" => scheduled_proposal.submitted_revision_id
        }
      else
        command.payload
      end
    end

    def scheduled_proposal
      @scheduled_proposal ||= Proposal.find_by(id: command.payload["proposal_id"]) ||
        raise(Rejected, "Proposal was not found.")
    end
  end
end
