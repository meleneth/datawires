# frozen_string_literal: true

module ProceduralPolicies
  class DescribeCommands
    Description = Data.define(
      :name,
      :version,
      :capability,
      :availability,
      :reason,
      :required_payload,
      :expected_effects
    ) do
      def available?
        availability == :available
      end
    end

    def self.call(meeting:, actor:, payloads: {}, at: Time.current, authorizer: Authorization::Policy)
      new(meeting:, actor:, payloads:, at:, authorizer:).call
    end

    def initialize(meeting:, actor:, payloads:, at:, authorizer:)
      raise ArgumentError, "meeting must be a Meeting" unless meeting.is_a?(Meeting)
      raise ArgumentError, "actor must be an ActorContext" unless actor.is_a?(ActorContext)
      raise ArgumentError, "payloads must be an object" unless payloads.is_a?(Hash)

      @meeting = meeting
      @actor = actor
      @payloads = payloads
      @at = at.in_time_zone
      @authorizer = authorizer
    end

    def call
      policy.commands.map { |definition| describe(definition) }.freeze
    end

    private

    attr_reader :meeting, :actor, :payloads, :at, :authorizer

    def policy
      @policy ||= meeting.procedural_policy.projection
    end

    def projection
      @projection ||= meeting.projection
    end

    def describe(definition)
      decision = authorizer.call(
        actor:,
        action: definition.capability,
        resource: { body: meeting.body, meeting:, at: }
      )
      return description(definition, :unavailable, decision.reason) unless decision.allowed?
      unless definition.allowed_statuses.include?(projection.status)
        reason = "#{definition.name.humanize} is unavailable while the meeting is #{projection.status}."
        return description(definition, :unavailable, reason)
      end

      payload = payloads.fetch(definition.name, {})
      missing = definition.payload.keys - payload.keys
      if missing.any?
        return description(
          definition,
          :prerequisite_needed,
          "Required input: #{missing.map(&:humanize).to_sentence}."
        )
      end
      payload_errors = ValidatePayload.call(payload:, definition:)
      return description(definition, :prerequisite_needed, payload_errors.to_sentence) if payload_errors.any?

      evaluation = EvaluateCommand.call(
        meeting:,
        command: envelope(definition, payload),
        definition:,
        projection:
      )
      description(definition, :available, nil, evaluation.projection_effects)
    rescue EvaluateCommand::Rejected => e
      description(definition, :unavailable, e.message)
    end

    def description(definition, availability, reason, expected_effects = [])
      Description.new(
        name: definition.name,
        version: definition.command_version,
        capability: definition.capability,
        availability:,
        reason:,
        required_payload: UuidTools.deep_freeze(definition.payload.deep_dup),
        expected_effects: UuidTools.deep_freeze(expected_effects.deep_dup)
      )
    end

    def envelope(definition, payload)
      Commands::Envelope.new(
        id: SecureRandom.uuid,
        type: definition.name,
        version: definition.command_version,
        stream_id: meeting.event_stream_id,
        expected_revision: projection.revision,
        actor:,
        timestamp: at,
        payload:
      )
    end
  end
end
