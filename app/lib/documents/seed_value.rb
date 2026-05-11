# frozen_string_literal: true

module Documents
  class SeedValue
    class << self
      def for(schema_node)
        new(schema_node).value
      end
    end

    attr_reader :schema_node

    def initialize(schema_node)
      @schema_node = schema_node.is_a?(Hash) ? schema_node : {}
    end

    def value
      return deep_copy(schema_node["default"]) if schema_node.key?("default")
      return deep_copy(schema_node["const"]) if schema_node.key?("const")

      enum_values = Array(schema_node["enum"])
      return deep_copy(enum_values.first) if enum_values.any?

      case normalized_type
      when "object"
        object_seed
      when "array"
        []
      when "boolean"
        false
      else
        nil
      end
    end

    private

    def normalized_type
      explicit_type || inferred_type
    end

    def explicit_type
      type = schema_node["type"]

      case type
      when Array
        preferred_type_from_union(type)
      when String
        type
      else
        nil
      end
    end

    def preferred_type_from_union(type_list)
      %w[object array boolean string integer number null].find { |candidate| type_list.include?(candidate) }
    end

    def inferred_type
      return "object" if schema_node["properties"].is_a?(Hash)
      return "array" if schema_node.key?("items")

      nil
    end

    def object_seed
      properties = schema_node["properties"]
      return {} unless properties.is_a?(Hash)

      Array(schema_node["required"]).each_with_object({}) do |property_name, seed|
        property_schema = properties[property_name]
        next unless property_schema.is_a?(Hash)

        seed[property_name] = self.class.for(property_schema)
      end
    end

    def deep_copy(value)
      value.deep_dup
    end
  end
end
