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
      event = Events::Data.new(
        type: definition.fetch(:event),
        version: 1,
        payload: command.payload,
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
  end
end
