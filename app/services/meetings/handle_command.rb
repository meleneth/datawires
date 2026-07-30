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
      unless command.version == definition.command_version
        raise Rejected, "Unsupported #{command.type.humanize(capitalize: false)} command version #{command.version}."
      end

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

      payload_errors = ProceduralPolicies::ValidatePayload.call(payload: command.payload, definition:)
      raise Rejected, payload_errors.to_sentence if payload_errors.any?
      evaluation = ProceduralPolicies::EvaluateCommand.call(
        meeting:,
        command:,
        definition:,
        projection:
      )
      event = Events::Data.new(
        type: definition.event_type,
        version: definition.event_version,
        payload: evaluation.event_payload,
        provenance: {
          "authorization" => { "allowed" => true, "capability" => definition.capability.to_s },
          "policy" => {
            "id" => meeting.procedural_policy.id,
            "revision_id" => meeting.procedural_policy.policy_document.head_revision_id
          },
          "projection_effects" => evaluation.projection_effects
        }
      )
      EventStreams::Append.call(stream: meeting.event_stream, command:, events: [ event ])
    rescue ProceduralPolicies::EvaluateCommand::Rejected => e
      raise Rejected, e.message
    end

    private

    attr_reader :meeting, :command, :authorizer
  end
end
