# frozen_string_literal: true

module ProceduralPolicies
  class Projection
    Command = Data.define(
      :name,
      :command_version,
      :capability,
      :allowed_statuses,
      :event_type,
      :event_version,
      :payload,
      :resources,
      :conditions,
      :event_payload,
      :effects
    )

    def self.build(body)
      validator = BodyValidator.new(body)
      raise ArgumentError, validator.errors.to_sentence unless validator.valid?

      new(body)
    end

    def initialize(body)
      @role_capabilities = body.fetch("role_capabilities").transform_values(&:freeze).freeze
      @commands = body.fetch("commands").to_h do |name, definition|
        [
          name,
          Command.new(
            name:,
            command_version: definition.fetch("command_version", 1),
            capability: definition.fetch("capability").to_sym,
            allowed_statuses: definition.fetch("allowed_statuses").freeze,
            event_type: definition.fetch("event_type"),
            event_version: definition.fetch("event_version"),
            payload: definition.fetch("payload", {}).freeze,
            resources: definition.fetch("resources", {}).freeze,
            conditions: definition.fetch("conditions", []).freeze,
            event_payload: definition.fetch("event_payload", {}).freeze,
            effects: definition.fetch("effects", []).freeze
          )
        ]
      end.freeze
    end

    def command(name)
      @commands[name]
    end

    def commands
      @commands.values
    end

    def capabilities
      @role_capabilities.keys
    end

    def roles_for(capability)
      @role_capabilities[capability.to_s]
    end
  end
end
