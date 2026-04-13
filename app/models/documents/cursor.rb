# frozen_string_literal: true

module Documents
  class Cursor
    attr_reader :source, :path

    def initialize(source:, path:)
      @source = source
      @path = path.is_a?(Documents::Path) ? path : Documents::Path.new(path)
    end

    def draft
      source
    end

    def ptr
      path.document_ptr
    end

    def root?
      path.root?
    end

    def name
      path.name
    end

    def at(path)
      self.class.new(source:, path:)
    end

    def parent
      return nil if root?

      self.class.new(source:, path: path.parent)
    end

    def child(segment)
      self.class.new(source:, path: path.child(segment))
    end

    def resolved_path
      @resolved_path ||= Documents::ResolvedPath.new(
        path:,
        schema_body: source.schema_document.body
      )
    end

    def resolves?
      resolved_path.schema_node.present?
    rescue Documents::ResolvedPath::InvalidTraversalError
      false
    end

    def schema_node
      resolved_path.schema_node || {}
    rescue Documents::ResolvedPath::InvalidTraversalError
      {}
    end

    def value
      JsonPtr.get(source.body, ptr)
    end

    def enum_values
      Array(schema_node["enum"]).presence
    end

    def type
      schema_node["type"] || inferred_type || "(no type)"
    end

    def required?
      return false if root?

      parent_schema_node = parent&.schema_node || {}
      Array(parent_schema_node["required"]).include?(name)
    end

    def present?
      return true if root?

      parent_value = JsonPtr.get(source.body, path.parent.document_ptr)

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

    def object?
      type == "object" || value.is_a?(Hash)
    end

    def array?
      type == "array" || value.is_a?(Array)
    end

    def composite?
      object? || array?
    end

    def openable?
      object?
    end

    def scalar?
      !object? && !array?
    end

    def array_element?
      resolved_path.array_element?
    rescue Documents::ResolvedPath::InvalidTraversalError
      false
    end

    def object_property?
      resolved_path.object_property?
    rescue Documents::ResolvedPath::InvalidTraversalError
      false
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

    def value_label
      return "missing" unless present?
      return "#{Array(value).length} items" if array?
      return "present" if object?

      value.inspect
    end

    def schema_child_keys
      properties = schema_node.is_a?(Hash) ? schema_node["properties"] : nil
      return [] unless properties.is_a?(Hash)

      properties.keys.sort
    end

    def children
      if object?
        schema_child_keys.map { |key| child(key) }
      elsif array?
        Array(value).each_index.map { |index| child(index.to_s) }
      else
        []
      end
    end

    private

    def inferred_type
      return "object" if value.is_a?(Hash)
      return "array" if value.is_a?(Array)

      nil
    end
  end
end
