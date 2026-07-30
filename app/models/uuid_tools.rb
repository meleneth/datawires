# frozen_string_literal: true

module UuidTools
  FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

  module_function

  def normalize(value)
    string = value.to_s
    raise ArgumentError, "must be a UUID" unless FORMAT.match?(string)

    string.downcase.freeze
  end

  def deep_freeze(value)
    case value
    when Hash
      value.each { |key, child| deep_freeze(key); deep_freeze(child) }
    when Array
      value.each { |child| deep_freeze(child) }
    end
    value.freeze
  end
end
