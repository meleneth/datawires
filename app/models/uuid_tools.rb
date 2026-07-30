# frozen_string_literal: true

require "digest"

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

  def derive(value, name)
    hex = Digest::SHA256.hexdigest("#{normalize(value)}:#{name}").first(32)
    hex[12] = "5"
    hex[16] = %w[8 9 a b][hex[16].to_i(16) % 4]
    normalize([ hex[0, 8], hex[8, 4], hex[12, 4], hex[16, 4], hex[20, 12] ].join("-"))
  end
end
