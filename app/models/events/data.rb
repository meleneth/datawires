# frozen_string_literal: true

module Events
  Data = ::Data.define(:type, :version, :payload, :provenance) do
    def initialize(type:, version:, payload: {}, provenance: {})
      raise ArgumentError, "type is required" if type.to_s.blank?
      raise ArgumentError, "version must be positive" unless version.is_a?(Integer) && version.positive?
      raise ArgumentError, "payload must be an object" unless payload.is_a?(Hash)
      raise ArgumentError, "provenance must be an object" unless provenance.is_a?(Hash)

      super(
        type: type.to_s.freeze,
        version:,
        payload: ::UuidTools.deep_freeze(payload.deep_dup),
        provenance: ::UuidTools.deep_freeze(provenance.deep_dup)
      )
      freeze
    end
  end
end
