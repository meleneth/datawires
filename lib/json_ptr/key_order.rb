# frozen_string_literal: true

module JsonPtr
  class KeyOrder
    # Default “schema pleasant” order. Adjust to your exact list.
    DEFAULT_PRIORITY = %w[
      $schema $id id $ref $defs definitions title description type enum const default
      properties required items additionalProperties oneOf anyOf allOf not
    ].freeze

    def initialize(priority: DEFAULT_PRIORITY)
      @priority_index = {}
      priority.each_with_index { |k, i| @priority_index[k] = i }
      @priority_fallback = priority.length
    end

    def sort_keys(keys)
      keys.sort_by { |k| sort_key(k) }
    end

    private

    def sort_key(k)
      s = k.to_s
      [@priority_index.fetch(s, @priority_fallback), s]
    end
  end
end
