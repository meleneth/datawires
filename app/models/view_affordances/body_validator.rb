# frozen_string_literal: true

module ViewAffordances
  class BodyValidator
    SUPPORTED_VERSIONS = [ 1 ].freeze
    SUPPORTED_RENDERERS = %w[timeline_d3 mud_player mud_choice_player].freeze

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
      validate_string(errors, config, "participant_kind", "config/participant_kind")
      validate_string(errors, config, "participant_key", "config/participant_key")
      validate_string(errors, config, "room_schema_key", "config/room_schema_key")
      validate_string(errors, config, "character_schema_key", "config/character_schema_key")
      validate_string(errors, config, "item_schema_key", "config/item_schema_key")
      validate_string(errors, config, "start_room_key", "config/start_room_key")
      validate_string(errors, config, "choice_room_schema_key", "config/choice_room_schema_key")
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
