# frozen_string_literal: true

module ProceduralPolicies
  class BodyValidator
    STATUSES = %w[scheduled open adjourned].freeze
    PAYLOAD_TYPES = %w[array boolean object string uuid].freeze
    CONDITION_OPERATIONS = %w[
      blank
      collection_excludes
      collection_includes
      collection_includes_value
      equals
      resource_equals
      path_collection_excludes
      path_collection_includes_value
      path_equals
      payload_in
      stack_empty
      stack_present
      stack_top_equals
      stack_top_not_equals
    ].freeze
    EFFECT_OPERATIONS = %w[
      append
      merge_last
      remove_matching
      set
      append_at_path
      merge
      stack_merge_top
      stack_pop
      stack_push
      stack_replace_top
    ].freeze
    EFFECT_CONDITIONS = %w[blank present].freeze
    BINDING_SOURCES = %w[
      actor_id
      command_id
      derived_id
      document_operation
      literal
      meeting_body_id
      payload
      payload_or_literal
      resource
      projection
      projection_path
      stack_top
      timestamp
      timestamp_iso8601
      vote_result
    ].freeze
    PROJECTION_FIELDS = Meetings::Projection.members.map(&:to_s).freeze
    RESOURCE_TYPES = Resources.types.freeze

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
      validate_role_capabilities
      commands = body["commands"]
      unless commands.is_a?(Hash)
        errors << "commands must be an object"
        return
      end

      commands.each { |name, definition| validate_command(name, definition) }
    end

    def validate_command(name, definition)
      prefix = "commands.#{name}"
      @current_resources = {}
      errors << "#{prefix} name must be non-empty" if name.blank?
      unless definition.is_a?(Hash)
        errors << "#{prefix} must be an object"
        return
      end
      @current_resources = definition.fetch("resources", {})

      capabilities = body.fetch("role_capabilities", {})
      errors << "#{prefix}.capability must be registered" unless capabilities.key?(definition["capability"])
      command_version = definition.fetch("command_version", 1)
      errors << "#{prefix}.command_version must be positive" unless command_version.is_a?(Integer) && command_version.positive?
      statuses = definition["allowed_statuses"]
      errors << "#{prefix}.allowed_statuses must contain known statuses" unless statuses.is_a?(Array) && statuses.present? && (statuses - STATUSES).empty?
      errors << "#{prefix}.event_type must be a non-empty string" unless definition["event_type"].is_a?(String) && definition["event_type"].present?
      errors << "#{prefix}.event_version must be positive" unless definition["event_version"].is_a?(Integer) && definition["event_version"].positive?
      validate_payload(definition["payload"], prefix)
      validate_resources(definition["resources"], prefix)
      validate_operations(definition["conditions"], CONDITION_OPERATIONS, prefix, "conditions")
      validate_operations(definition["effects"], EFFECT_OPERATIONS, prefix, "effects")
      validate_bindings(definition["event_payload"], "#{prefix}.event_payload")
    ensure
      @current_resources = {}
    end

    def validate_role_capabilities
      capabilities = body["role_capabilities"]
      unless capabilities.is_a?(Hash)
        errors << "role_capabilities must be an object"
        return
      end

      capabilities.each do |capability, roles|
        errors << "role_capabilities names must be non-empty" if capability.blank?
        unless roles.is_a?(Array) && roles.present? && roles.all? { |role| role.is_a?(String) && role.present? } && roles.uniq == roles
          errors << "role_capabilities.#{capability} must contain unique non-empty roles"
        end
      end
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
        validate_operation_shape(operation, "#{prefix}.#{key}[#{index}]", key)
        validate_effect_condition(operation["when"], "#{prefix}.#{key}[#{index}].when") if key == "effects"
        validate_bindings(operation, "#{prefix}.#{key}[#{index}]")
      end
    end

    def validate_operation_shape(operation, prefix, collection)
      if collection == "effects"
        errors << "#{prefix}.field is required" if operation["field"].blank?
        validate_pointer(operation["path"], "#{prefix}.path") if operation["op"] == "append_at_path"
        if operation["op"] != "stack_pop" && !operation.key?("value")
          errors << "#{prefix}.value is required"
        end
        return
      end

      field_optional = operation["op"] == "resource_equals"
      field_optional ||= operation["op"] == "payload_in"
      errors << "#{prefix}.field is required" if !field_optional && operation["field"].blank?
      validate_resource_reference(operation, prefix) if operation["op"] == "resource_equals"
      validate_pointer(operation["path"], "#{prefix}.path") if operation["op"].start_with?("path_")
      if !%w[blank payload_in stack_empty stack_present].include?(operation["op"]) && !operation.key?("value")
        errors << "#{prefix}.value is required"
      end
    end

    def validate_resource_reference(reference, prefix)
      descriptor = @current_resources[reference["resource"]]
      return errors << "#{prefix}.resource must be declared" unless descriptor

      attributes = Resources.attributes_for(descriptor["type"])
      errors << "#{prefix}.attribute must be registered" unless attributes.include?(reference["attribute"])
    rescue KeyError
      errors << "#{prefix}.attribute must be registered"
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

    def validate_pointer(pointer, prefix)
      JsonPtr::Pointer.parse(pointer)
    rescue ArgumentError, TypeError
      errors << "#{prefix} must be a JSON Pointer"
    end

    def validate_bindings(value, prefix)
      case value
      when Array
        value.each_with_index { |entry, index| validate_bindings(entry, "#{prefix}[#{index}]") }
      when Hash
        if value.key?("source")
          errors << "#{prefix}.source must be registered" unless BINDING_SOURCES.include?(value["source"])
          if value["source"] == "derived_id" && value["name"].blank?
            errors << "#{prefix}.name must be non-empty"
          end
          validate_resource_binding(value, prefix) if value["source"] == "resource"
          validate_stack_top_binding(value, prefix) if value["source"] == "stack_top"
          validate_document_operation_binding(value, prefix) if value["source"] == "document_operation"
          validate_projection_binding(value, prefix) if value["source"].in?(%w[projection projection_path])
          validate_vote_result_binding(value, prefix) if value["source"] == "vote_result"
        else
          value.each { |key, entry| validate_bindings(entry, "#{prefix}.#{key}") }
        end
      end
    end

    def validate_resource_binding(binding, prefix)
      resource_name = binding["resource"]
      descriptor = @current_resources[resource_name]
      return errors << "#{prefix}.resource must be declared" unless descriptor

      attributes = Resources.attributes_for(descriptor["type"])
      errors << "#{prefix}.attribute must be registered" unless attributes.include?(binding["attribute"])
    rescue KeyError
      errors << "#{prefix}.attribute must be registered"
    end

    def validate_stack_top_binding(binding, prefix)
      unless PROJECTION_FIELDS.include?(binding["field"])
        errors << "#{prefix}.field must be a registered projection field"
      end
      errors << "#{prefix}.attribute must be non-empty" if binding["attribute"].blank?
    end

    def validate_document_operation_binding(binding, prefix)
      %w[document operation current_version].each do |key|
        errors << "#{prefix}.#{key} is required" unless binding[key].is_a?(Hash)
        validate_bindings(binding[key], "#{prefix}.#{key}") if binding[key].is_a?(Hash)
      end
    end

    def validate_projection_binding(binding, prefix)
      unless PROJECTION_FIELDS.include?(binding["field"])
        errors << "#{prefix}.field must be a registered projection field"
      end
      validate_pointer(binding["path"], "#{prefix}.path") if binding["source"] == "projection_path"
    end

    def validate_vote_result_binding(binding, prefix)
      unless PROJECTION_FIELDS.include?(binding["field"])
        errors << "#{prefix}.field must be a registered projection field"
      end
    end
  end
end
