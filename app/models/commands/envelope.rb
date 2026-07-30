# frozen_string_literal: true

module Commands
  Envelope = Data.define(
    :id,
    :type,
    :version,
    :stream_id,
    :expected_revision,
    :actor,
    :timestamp,
    :payload,
    :correlation_id,
    :causation_id
  ) do
    def initialize(id:, type:, version:, stream_id:, expected_revision:, actor:, timestamp:, payload: {}, correlation_id: nil, causation_id: nil)
      raise ArgumentError, "actor must be an ActorContext" unless actor.is_a?(ActorContext)
      raise ArgumentError, "expected revision must be non-negative" unless expected_revision.is_a?(Integer) && expected_revision >= 0
      raise ArgumentError, "payload must be an object" unless payload.is_a?(Hash)

      super(
        id: ::UuidTools.normalize(id),
        type: required_string(type, "type"),
        version: positive_integer(version, "version"),
        stream_id: ::UuidTools.normalize(stream_id),
        expected_revision:,
        actor:,
        timestamp: timestamp.in_time_zone.freeze,
        payload: ::UuidTools.deep_freeze(payload.deep_dup),
        correlation_id: optional_uuid(correlation_id),
        causation_id: optional_uuid(causation_id)
      )
      freeze
    end

    private

    def required_string(value, name)
      string = value.to_s
      raise ArgumentError, "#{name} is required" if string.blank?

      string.freeze
    end

    def positive_integer(value, name)
      raise ArgumentError, "#{name} must be positive" unless value.is_a?(Integer) && value.positive?

      value
    end

    def optional_uuid(value)
      value.nil? ? nil : ::UuidTools.normalize(value)
    end
  end
end
