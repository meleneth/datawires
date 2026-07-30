# frozen_string_literal: true

module ProceduralPolicies
  class LegacyEventEffects
    BINDING_SOURCES = %w[
      event_actor_id
      event_payload
      event_payload_or_literal
      event_timestamp
      event_timestamp_iso8601
      literal
    ].freeze
    PATH = Rails.root.join(
      "config/procedural_policies/legacy_meeting_event_effects_v1.json"
    ).freeze

    def self.call(record:)
      new(record:).call
    end

    def self.mappings
      @mappings ||= begin
        document = JSON.parse(PATH.read)
        validate!(document)
        UuidTools.deep_freeze(document.fetch("events"))
      end
    end

    def self.validate!(document)
      raise ArgumentError, "legacy event mapping version must be 1" unless document["version"] == 1
      raise ArgumentError, "legacy event mappings must be an object" unless document["events"].is_a?(Hash)

      document.fetch("events").each_value do |versions|
        raise ArgumentError, "legacy event versions must be an object" unless versions.is_a?(Hash)

        versions.each_value do |definition|
          effects = definition["effects"]
          raise ArgumentError, "legacy event effects must be an array" unless effects.is_a?(Array)

          effects.each { |effect| validate_effect!(effect) }
        end
      end
      true
    end

    def self.validate_effect!(effect)
      unless effect.is_a?(Hash) && ApplyEffects::OPERATIONS.include?(effect["op"])
        raise ArgumentError, "legacy event effect operation is not registered"
      end
      unless ApplyEffects::FIELDS.include?(effect["field"])
        raise ArgumentError, "legacy event effect field is not registered"
      end

      validate_bindings!(effect)
    end
    private_class_method :validate_effect!

    def self.validate_bindings!(value)
      case value
      when Array
        value.each { |entry| validate_bindings!(entry) }
      when Hash
        if value.key?("source")
          unless BINDING_SOURCES.include?(value["source"])
            raise ArgumentError, "legacy event binding is not registered"
          end
        else
          value.each_value { |entry| validate_bindings!(entry) }
        end
      end
    end
    private_class_method :validate_bindings!

    def initialize(record:)
      @record = record
    end

    def call
      effects = self.class.mappings
        .dig(record.event_type, record.event_version.to_s, "effects")
      return [] unless effects

      effects.map { |effect| resolve(effect) }
    end

    private

    attr_reader :record

    def resolve(value)
      return value.map { |entry| resolve(entry) } if value.is_a?(Array)
      return value unless value.is_a?(Hash)
      return value.transform_values { |entry| resolve(entry) } unless value.key?("source")

      case value.fetch("source")
      when "event_actor_id" then record.actor_id
      when "event_payload" then value["key"] ? record.payload[value["key"]] : record.payload
      when "event_payload_or_literal" then record.payload[value["key"]].presence || value["value"]
      when "event_timestamp" then record.occurred_at
      when "event_timestamp_iso8601" then record.occurred_at.iso8601
      when "literal" then value["value"]
      else raise ArgumentError, "unregistered legacy event binding"
      end
    end
  end
end
