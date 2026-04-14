# app/lib/documents/resolved_path.rb
# frozen_string_literal: true

module Documents
  class ResolvedPath
    class InvalidTraversalError < StandardError; end

    attr_reader :path, :schema_body

    def initialize(path:, schema_body:)
      @path = path.is_a?(Documents::Path) ? path : Documents::Path.new(path)
      @schema_body = schema_body.is_a?(Hash) ? schema_body : {}
    end

    def schema_node
      @schema_node ||= resolution.fetch(:schema_node)
    end

    def array_element?
      resolution.fetch(:array_element)
    end

    def object_property?
      resolution.fetch(:object_property)
    end

    private

    def resolution
      @resolution ||= begin
        resolver = Documents::SchemaResolver.new(root_schema: schema_body)
        current = resolver.resolve(schema_body)

        last_array_element = false
        last_object_property = false

        path.tokens.each do |token|
          current = resolver.resolve(current)
          last_array_element = false
          last_object_property = false

          if object_schema?(current)
            properties = current["properties"]
            unless properties.is_a?(Hash) && properties.key?(token)
              raise InvalidTraversalError, "property #{token.inspect} not found"
            end

            current = properties[token]
            last_object_property = true
            next
          end

          if array_schema?(current)
            unless integer_token?(token)
              raise InvalidTraversalError, "array index expected, got #{token.inspect}"
            end

            items = current["items"]
            if items.blank?
              raise InvalidTraversalError, "array schema missing items for #{path}"
            end

            current = items
            last_array_element = true
            next
          end

          raise InvalidTraversalError, "cannot traverse #{token.inspect} through #{current.inspect}"
        end

        current = resolver.resolve(current)

        {
          schema_node: current || {},
          array_element: last_array_element,
          object_property: last_object_property
        }
      end
    end

    def object_schema?(node)
      node.is_a?(Hash) && (
        node["type"] == "object" ||
        node["properties"].is_a?(Hash)
      )
    end

    def array_schema?(node)
      node.is_a?(Hash) && (
        node["type"] == "array" ||
        node.key?("items")
      )
    end

    def integer_token?(token)
      Integer(token, 10)
      true
    rescue ArgumentError, TypeError
      false
    end
  end
end
