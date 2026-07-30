# frozen_string_literal: true

module ProceduralPolicies
  class Projection
    Command = Data.define(:name, :capability, :allowed_statuses, :event_type, :event_version, :payload)

    def self.build(body)
      validator = BodyValidator.new(body)
      raise ArgumentError, validator.errors.to_sentence unless validator.valid?

      new(body)
    end

    def initialize(body)
      @commands = body.fetch("commands").to_h do |name, definition|
        [
          name,
          Command.new(
            name:,
            capability: definition.fetch("capability").to_sym,
            allowed_statuses: definition.fetch("allowed_statuses").freeze,
            event_type: definition.fetch("event_type"),
            event_version: definition.fetch("event_version"),
            payload: definition.fetch("payload", {}).freeze
          )
        ]
      end.freeze
    end

    def command(name)
      @commands[name]
    end
  end
end
