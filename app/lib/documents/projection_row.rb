module Documents
  # frozen_string_literal: true

  class ProjectionRow
    def initialize(projection:, path:)
      @projection = projection
      @path = path.is_a?(Documents::Path) ? path : Documents::Path.new(path)
    end

    attr_reader :path

    def draft
      @projection.source
    end

    def name
      document_pointer.tokens.last&.unescaped.to_s
    end

    def schema_node
      @schema_node ||= JsonPtr.get(draft.schema_document.body, path.schema_ptr) || {}
    end

    def enum_values
      Array(schema_node["enum"]).presence
    end

    def type
      schema_node["type"] || "(no type)"
    end

    def required?
      parent_required_keys.include?(name)
    end

    def present?
      parent_node.is_a?(Hash) && (parent_node.key?(name) || parent_node.key?(name.to_sym))
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

    private

    def document_pointer
      @document_pointer ||= JsonPtr::Pointer.parse(path.document_ptr)
    end

    def parent_path
      @parent_path ||= document_pointer.tokens[0...-1]
        .map(&:unescaped)
        .reduce(Documents::Path.new("/")) { |current, token| current.child(token) }
    end

    def parent_node
      JsonPtr.get(draft.body, parent_path.document_ptr)
    end

    def parent_schema_node
      JsonPtr.get(draft.schema_document.body, parent_path.schema_ptr) || {}
    end

    def parent_required_keys
      Array(parent_schema_node["required"])
    end
  end
end
