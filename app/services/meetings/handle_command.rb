# frozen_string_literal: true

module Meetings
  class HandleCommand
    class Rejected < StandardError; end

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
      definition = meeting.procedural_policy.projection.command(command.type)
      raise Rejected, "Unsupported meeting command." unless definition

      decision = authorizer.call(
        actor: command.actor,
        action: definition.capability,
        resource: { body: meeting.body, meeting:, at: command.timestamp }
      )
      raise Rejected, decision.reason unless decision.allowed?

      projection = meeting.projection
      unless definition.allowed_statuses.include?(projection.status)
        raise Rejected, "#{command.type.humanize} is unavailable while the meeting is #{projection.status}."
      end

      validate_payload!
      validate_procedure!(projection)
      event = Events::Data.new(
        type: definition.event_type,
        version: definition.event_version,
        payload: event_payload,
        provenance: {
          "authorization" => { "allowed" => true, "capability" => definition.capability.to_s },
          "policy" => {
            "id" => meeting.procedural_policy.id,
            "revision_id" => meeting.procedural_policy.policy_document.head_revision_id
          }
        }
      )
      EventStreams::Append.call(stream: meeting.event_stream, command:, events: [ event ])
    end

    private

    attr_reader :meeting, :command, :authorizer

    def validate_payload!
      definition = meeting.procedural_policy.projection.command(command.type)
      definition.payload.each do |key, type|
        value = command.payload[key]
        valid = case type
        when "array" then value.is_a?(Array)
        when "boolean" then [ true, false ].include?(value)
        when "string" then value.is_a?(String)
        when "uuid" then UuidTools::FORMAT.match?(value.to_s)
        end
        raise Rejected, "#{key.humanize} must be a #{type}." unless valid
      end
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
