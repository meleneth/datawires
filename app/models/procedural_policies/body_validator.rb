# frozen_string_literal: true

module ProceduralPolicies
  class BodyValidator
    CAPABILITIES = Authorization::BodyPolicy::ROLE_CAPABILITIES.keys.map(&:to_s).freeze
    STATUSES = %w[scheduled open adjourned].freeze
    PAYLOAD_TYPES = %w[array boolean string uuid].freeze
    CONDITION_OPERATIONS = %w[blank collection_excludes collection_includes equals resource_equals].freeze
    EFFECT_OPERATIONS = %w[append merge_last remove_matching set].freeze
    EFFECT_CONDITIONS = %w[blank present].freeze
    BINDING_SOURCES = %w[
      actor_id
      literal
      meeting_body_id
      payload
      payload_or_literal
      resource
      timestamp
      timestamp_iso8601
    ].freeze
    PROJECTION_FIELDS = Meetings::Projection.members.map(&:to_s).freeze
    RESOURCE_TYPES = %w[proposal].freeze

    attr_reader :errors

    def initialize(body)
      @body = body
      @errors = []
      validate
    end

    def valid?
      errors.empty?
    end

    private

    attr_reader :body

    def validate
      unless body.is_a?(Hash)
        errors << "body must be an object"
        return
      end

      errors << "version must be 1" unless body["version"] == 1
      errors << "name must be a non-empty string" unless body["name"].is_a?(String) && body["name"].present?
      commands = body["commands"]
      unless commands.is_a?(Hash)
        errors << "commands must be an object"
        return
      end

      commands.each { |name, definition| validate_command(name, definition) }
    end

    def validate_command(name, definition)
      prefix = "commands.#{name}"
      errors << "#{prefix} name must be non-empty" if name.blank?
      unless definition.is_a?(Hash)
        errors << "#{prefix} must be an object"
        return
      end

      errors << "#{prefix}.capability must be registered" unless CAPABILITIES.include?(definition["capability"])
      statuses = definition["allowed_statuses"]
      errors << "#{prefix}.allowed_statuses must contain known statuses" unless statuses.is_a?(Array) && statuses.present? && (statuses - STATUSES).empty?
      errors << "#{prefix}.event_type must be a non-empty string" unless definition["event_type"].is_a?(String) && definition["event_type"].present?
      errors << "#{prefix}.event_version must be positive" unless definition["event_version"].is_a?(Integer) && definition["event_version"].positive?
      validate_payload(definition["payload"], prefix)
      validate_resources(definition["resources"], prefix)
      validate_operations(definition["conditions"], CONDITION_OPERATIONS, prefix, "conditions")
      validate_operations(definition["effects"], EFFECT_OPERATIONS, prefix, "effects")
      validate_bindings(definition["event_payload"], "#{prefix}.event_payload")
    end

    def validate_payload(payload, prefix)
      return if payload.nil?
      unless payload.is_a?(Hash)
        errors << "#{prefix}.payload must be an object"
        return
      end

      payload.each do |key, type|
        errors << "#{prefix}.payload.#{key} must use a registered type" unless PAYLOAD_TYPES.include?(type)
      end
    end

    def validate_resources(resources, prefix)
      return if resources.nil?
      unless resources.is_a?(Hash)
        errors << "#{prefix}.resources must be an object"
        return
      end

      resources.each do |name, descriptor|
        unless descriptor.is_a?(Hash) && RESOURCE_TYPES.include?(descriptor["type"])
          errors << "#{prefix}.resources.#{name} must use a registered resource type"
          next
        end
        validate_bindings(descriptor["id"], "#{prefix}.resources.#{name}.id")
      end
    end

    def validate_operations(operations, registry, prefix, key)
      return if operations.nil?
      unless operations.is_a?(Array)
        errors << "#{prefix}.#{key} must be an array"
        return
      end

      operations.each_with_index do |operation, index|
        unless operation.is_a?(Hash) && registry.include?(operation["op"])
          errors << "#{prefix}.#{key}[#{index}] must use a registered operation"
          next
        end
        if operation["field"] && !PROJECTION_FIELDS.include?(operation["field"])
          errors << "#{prefix}.#{key}[#{index}].field must be a registered projection field"
        end
        validate_effect_condition(operation["when"], "#{prefix}.#{key}[#{index}].when") if key == "effects"
        validate_bindings(operation, "#{prefix}.#{key}[#{index}]")
      end
    end

    def validate_effect_condition(condition, prefix)
      return if condition.nil?
      unless condition.is_a?(Hash)
        errors << "#{prefix} must be an object"
        return
      end

      errors << "#{prefix}.op must be registered" unless EFFECT_CONDITIONS.include?(condition["op"])
      errors << "#{prefix}.field must be a registered projection field" unless PROJECTION_FIELDS.include?(condition["field"])
    end

    def validate_bindings(value, prefix)
      case value
      when Array
        value.each_with_index { |entry, index| validate_bindings(entry, "#{prefix}[#{index}]") }
      when Hash
        if value.key?("source")
          errors << "#{prefix}.source must be registered" unless BINDING_SOURCES.include?(value["source"])
        else
          value.each { |key, entry| validate_bindings(entry, "#{prefix}.#{key}") }
        end
      end
    end
  end
end
