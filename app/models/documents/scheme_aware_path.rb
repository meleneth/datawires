# frozen_string_literal: true

module Documents
  class SchemaAwarePath
    class InvalidPathError < ArgumentError; end
    class InvalidTraversalError < ArgumentError; end

    attr_reader :schema_body, :document_ptr

    def initialize(schema_body:, document_ptr: "/")
      @schema_body = schema_body
      @document_ptr = normalize_ptr(document_ptr)
    end

    def root?
      document_ptr == "/"
    end

    def document_pointer
      @document_pointer ||= JsonPtr::Pointer.parse(document_ptr)
    end

    def tokens
      document_pointer.tokens.map(&:unescaped)
    end

    def schema_ptr
      @schema_ptr ||= resolve_schema_ptr
    end

    def schema_node
      JsonPtr.get(schema_body, schema_ptr) || {}
    end

    def child(segment)
      self.class.new(
        schema_body: schema_body,
        document_ptr: document_pointer.child(segment.to_s).to_s
      )
    end

    def parent
      return nil if root?

      parent_tokens = tokens[0...-1]
      ptr = parent_tokens.reduce(JsonPtr::Pointer.parse("/")) do |pointer, token|
        pointer.child(token)
      end

      self.class.new(
        schema_body: schema_body,
        document_ptr: ptr.to_s
      )
    end

    def name
      tokens.last
    end

    def array_element?
      return false if root?

      parent&.schema_type == "array"
    end

    def object_property?
      return false if root?

      parent&.schema_type == "object"
    end

    def schema_type
      schema_node["type"]
    end

    private

    def normalize_ptr(raw)
      JsonPtr::Pointer.parse(raw.presence || "/").to_s
    rescue ArgumentError => e
      raise InvalidPathError, e.message
    end

    def resolve_schema_ptr
      current_schema_ptr = "/"
      current_schema_node = schema_body

      tokens.each do |segment|
        case current_schema_node["type"]
        when "object"
          properties = current_schema_node["properties"]
          unless properties.is_a?(Hash)
            raise InvalidTraversalError, "expected object properties at #{current_schema_ptr}"
          end

          unless properties.key?(segment)
            raise InvalidTraversalError, "unknown property #{segment.inspect} at #{current_schema_ptr}"
          end

          current_schema_ptr = JsonPtr::Pointer.parse(current_schema_ptr)
            .child("properties")
            .child(segment)
            .to_s

          current_schema_node = properties.fetch(segment)

        when "array"
          items = current_schema_node["items"]
          unless items.is_a?(Hash)
            raise InvalidTraversalError, "expected array items at #{current_schema_ptr}"
          end

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
