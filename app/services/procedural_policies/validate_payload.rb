# frozen_string_literal: true

module ProceduralPolicies
  class ValidatePayload
    def self.call(payload:, definition:)
      definition.payload.filter_map do |key, type|
        value = payload[key]
        "#{key.humanize} must be a #{type}." unless valid?(value, type)
      end.freeze
    end

    def self.valid?(value, type)
      case type
      when "array" then value.is_a?(Array)
      when "boolean" then [ true, false ].include?(value)
      when "object" then value.is_a?(Hash)
      when "string" then value.is_a?(String)
      when "uuid" then UuidTools::FORMAT.match?(value.to_s)
      else false
      end
    end
    private_class_method :valid?
  end
end
