# frozen_string_literal: true

module Documents
  class ResolvedPath
    class InvalidTraversalError < ArgumentError; end

    attr_reader :path, :schema_body

    def initialize(path:, schema_body:)
      @path = path.is_a?(Documents::Path) ? path : Documents::Path.new(path)
      @schema_body = schema_body
    end

    def document_ptr
      path.document_ptr
    end

    def tokens
      path.tokens
    end

    def root?
      path.root?
    end

    def name
      path.name
    end

    def child(segment)
      self.class.new(
        path: path.child(segment),
        schema_body: schema_body
      )
    end

    def parent
      parent_path = path.parent
      return nil unless parent_path

      self.class.new(
        path: parent_path,
        schema_body: schema_body
      )
    end

    def schema_ptr
      @schema_ptr ||= resolve_schema_ptr
    end

    def schema_node
      JsonPtr.get(schema_body, schema_ptr) || {}
    end

    def schema_type
      schema_node["type"]
    end

    def array_element?
      return false if root?

      parent&.schema_type == "array"
    end

    def object_property?
      return false if root?

      parent&.schema_type == "object"
    end

    private

    def resolve_schema_ptr
      current_schema_ptr = "/"
      current_schema_node = schema_body

      tokens.each do |segment|
        case current_schema_node["type"]
        when "object"
          properties = current_schema_node["properties"]
          raise InvalidTraversalError, "expected object properties at #{current_schema_ptr}" unless properties.is_a?(Hash)
          raise InvalidTraversalError, "unknown property #{segment.inspect} at #{current_schema_ptr}" unless properties.key?(segment)

          current_schema_ptr = JsonPtr::Pointer.parse(current_schema_ptr)
            .child("properties")
            .child(segment)
            .to_s

          current_schema_node = properties.fetch(segment)
        when "array"
          items = current_schema_node["items"]
          raise InvalidTraversalError, "expected array items at #{current_schema_ptr}" unless items.is_a?(Hash)

          current_schema_ptr = JsonPtr::Pointer.parse(current_schema_ptr)
            .child("items")
            .to_s

          current_schema_node = items
        else
          raise InvalidTraversalError,
                "cannot traverse segment #{segment.inspect} through schema type #{current_schema_node['type'].inspect}"
        end
      end

      current_schema_ptr
    end
  end
end
