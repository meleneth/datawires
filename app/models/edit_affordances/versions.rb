# frozen_string_literal: true

module EditAffordances
  module Versions
    CURRENT = 1
    SUPPORTED = [ CURRENT ].freeze

    module_function

    def upgrade(body)
      normalized_body = body.presence || {}
      version = normalized_body["version"]

      return normalized_body.merge("version" => CURRENT) if version.blank?
      return normalized_body if SUPPORTED.include?(version.to_i)

      raise UnsupportedVersionError, "unsupported edit affordance version: #{version.inspect}"
    end

    class UnsupportedVersionError < ArgumentError; end
  end
end
