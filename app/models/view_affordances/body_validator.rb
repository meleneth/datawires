# frozen_string_literal: true

module ViewAffordances
  class BodyValidator
    SUPPORTED_VERSIONS = [ 1 ].freeze
    SUPPORTED_RENDERERS = %w[timeline_d3].freeze

    attr_reader :body

    def initialize(body)
      @body = body
    end

    def errors
      @errors ||= validate
    end

    def valid?
      errors.empty?
    end

    private

    def validate
      errors = []
      return [ "body must be a JSON object" ] unless body.is_a?(Hash)

      validate_version(errors)
      validate_string(errors, body, "title", "title")
      validate_renderer(errors)
      validate_config(errors)

      errors
    end

    def validate_version(errors)
      version = body["version"]

      if !body.key?("version") || version == ""
        errors << "version is required"
      elsif !integer?(version)
        errors << "version must be an integer"
      elsif !SUPPORTED_VERSIONS.include?(version.to_i)
        errors << "version #{version.inspect} is not supported"
      end
    end

    def validate_renderer(errors)
      renderer = body["renderer"]

      if !renderer.is_a?(String) || renderer.blank?
        errors << "renderer is required"
      elsif !SUPPORTED_RENDERERS.include?(renderer)
        errors << "renderer must be one of: #{SUPPORTED_RENDERERS.join(', ')}"
      end
    end

    def validate_config(errors)
      return unless body.key?("config")

      config = body["config"]
      unless config.is_a?(Hash)
        errors << "config must be an object"
        return
      end

      validate_string(errors, config, "schema_key", "config/schema_key")
      validate_string(errors, config, "relative_time_label", "config/relative_time_label")
    end

    def validate_string(errors, object, key, path)
      return unless object.key?(key)
      return if object[key].is_a?(String)

      errors << "#{path} must be a string"
    end

    def integer?(value)
      value.is_a?(Integer) || value.to_s.match?(/\A\d+\z/)
    end
  end
end
