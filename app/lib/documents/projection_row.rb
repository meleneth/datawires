# frozen_string_literal: true

module Documents
  class ProjectionRow
    attr_reader :path

    def initialize(projection:, path:)
      @projection = projection
      @path = path.is_a?(Documents::Path) ? path : Documents::Path.new(path)
    end

    def draft
      @projection.source
    end

    def resolved_path
      @resolved_path ||= @projection.resolved_path(path)
    end

    def name
      path.name
    end

    def schema_node
      resolved_path.schema_node || {}
    end

    def enum_values
      Array(schema_node["enum"]).presence
    end

    def type
      schema_node["type"] || "(no type)"
    end

    def required?
      return false if path.root?

      parent_schema_node = resolved_path.parent&.schema_node || {}
      Array(parent_schema_node["required"]).include?(name)
    end

    def present?
      return true if path.root?

      parent_value = JsonPtr.get(draft.body, path.parent.document_ptr)

      if array_element?
        return false unless parent_value.is_a?(Array)

        index = Integer(name, 10)
        return index >= 0 && index < parent_value.length
      end

      return false unless parent_value.is_a?(Hash)

      parent_value.key?(name) || parent_value.key?(name.to_sym)
    rescue ArgumentError, TypeError
      false
    end

    def value
      JsonPtr.get(draft.body, path.document_ptr)
    end

    def composite?
      type == "object" || type == "array" || value.is_a?(Hash) || value.is_a?(Array)
    end

    def openable?
      composite?
    end

    def scalar?
      !composite?
    end

    def array_element?
      resolved_path.array_element?
    end

    def object_property?
      resolved_path.object_property?
    end

    def input_kind
      return :select if enum_values.present?

      case type
      when "boolean"
        :checkbox
      when "integer", "number"
        :number
      else
        :text
      end
    end

    def field_value
      return value if present?

      case input_kind
      when :checkbox
        false
      else
        nil
      end
    end

    def checkbox_value
      ActiveModel::Type::Boolean.new.cast(field_value)
    end

    def ptr
      path.document_ptr
    end

    def value_label
      return "missing" unless present?
      return "present" if composite?

      value.inspect
    end
  end
end
