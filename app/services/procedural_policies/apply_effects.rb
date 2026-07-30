# frozen_string_literal: true

module ProceduralPolicies
  class ApplyEffects
    FIELDS = Meetings::Projection.members.map(&:to_s).freeze
    OPERATIONS = %w[append merge_last remove_matching set].freeze

    def self.call(state:, effects:)
      new(state:, effects:).call
    end

    def initialize(state:, effects:)
      @state = state.deep_dup
      @effects = effects
    end

    def call
      effects.each { |effect| apply(effect) }
      UuidTools.deep_freeze(state)
    end

    private

    attr_reader :state, :effects

    def apply(effect)
      return unless effect_applies?(effect["when"])

      operation = effect.fetch("op")
      field = effect.fetch("field")
      raise ArgumentError, "unregistered projection operation" unless OPERATIONS.include?(operation)
      raise ArgumentError, "unregistered projection field" unless FIELDS.include?(field)

      case operation
      when "set"
        state[field.to_sym] = effect["value"]
      when "append"
        state[field.to_sym] = Array(state[field.to_sym]) + [ compact_hash(effect.fetch("value")) ]
      when "remove_matching"
        state[field.to_sym] = Array(state[field.to_sym]).reject do |entry|
          entry[effect.fetch("match_field")] == effect["value"]
        end
      when "merge_last"
        values = Array(state[field.to_sym]).deep_dup
        values.last&.merge!(compact_hash(effect.fetch("value")))
        state[field.to_sym] = values
      end
    end

    def effect_applies?(condition)
      return true unless condition

      field = condition.fetch("field")
      raise ArgumentError, "unregistered projection field" unless FIELDS.include?(field)

      case condition.fetch("op")
      when "present" then state[field.to_sym].present?
      when "blank" then state[field.to_sym].blank?
      else raise ArgumentError, "unregistered effect condition"
      end
    end

    def compact_hash(value)
      value.is_a?(Hash) ? value.compact : value
    end
  end
end
