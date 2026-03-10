# app/services/schema_mutations.rb
# frozen_string_literal: true

class SchemaMutations
  class << self
    def ensure_object_root!(body, at: "/")
      node = fetch_node!(body, at)
      node["type"] ||= "object"
      node["properties"] ||= {}
      node["required"] ||= []
      write_node!(body, at, node)
    end

    def add_property!(body, at: "/", name:, type:, required: false)
      node = object_node!(body, at)
      props = node["properties"]

      raise ArgumentError, "property exists" if props.key?(name)

      props[name] = starter_property(type)
      set_required_on_node!(node, name:, required:)
      write_node!(body, at, node)
    end

    def remove_property!(body, at: "/", name:)
      node = object_node!(body, at)

      node["properties"].delete(name)
      node["required"] = Array(node["required"]).reject { |x| x == name }

      write_node!(body, at, node)
    end

    def rename_property!(body, at: "/", old_name:, new_name:)
      node = object_node!(body, at)
      props = node["properties"]

      raise ArgumentError, "missing property" unless props.key?(old_name)
      raise ArgumentError, "property exists" if props.key?(new_name)

      props[new_name] = props.delete(old_name)
      node["required"] = Array(node["required"]).map { |x| x == old_name ? new_name : x }

      write_node!(body, at, node)
    end

    def change_property_type!(body, at: "/", name:, type:)
      node = object_node!(body, at)
      props = node["properties"]

      raise ArgumentError, "missing property" unless props.key?(name)

      props[name] = normalize_property_for_type(props[name], type)
      write_node!(body, at, node)
    end

    def set_required!(body, at: "/", name:, required:)
      node = object_node!(body, at)

      set_required_on_node!(node, name:, required:)
      write_node!(body, at, node)
    end

    private

    def fetch_node!(body, at)
      node = JsonPtr.fetch(body, at, default: JsonPtr::UNDEFINED)
      raise KeyError, "missing path: #{at}" if node.equal?(JsonPtr::UNDEFINED)
      raise ArgumentError, "schema node at #{at} must be an object" unless node.is_a?(Hash)

      node.deep_dup
    end

    def write_node!(body, at, node)
      updated =
        if at == "/"
          node
        else
          JsonPtr.set(body, at, node)
        end

      body.replace(updated)
    end

    def object_node!(body, at)
      node = fetch_node!(body, at)

      node["type"] ||= "object"
      raise ArgumentError, "node at #{at} is not an object schema" unless node["type"] == "object"

      node["properties"] ||= {}
      node["required"] ||= []
      node
    end

    def set_required_on_node!(node, name:, required:)
      req = Array(node["required"]).uniq

      node["required"] =
        if required
          req | [name]
        else
          req.reject { |x| x == name }
        end
    end

    def starter_property(type)
      case type
      when "object"
        { "type" => "object", "properties" => {}, "required" => [] }
      when "array"
        { "type" => "array", "items" => {} }
      else
        { "type" => type }
      end
    end

    def normalize_property_for_type(property, type)
      property = property.deep_dup
      property["type"] = type

      case type
      when "object"
        property["properties"] ||= {}
        property["required"] ||= []
        property.delete("items")
      when "array"
        property["items"] ||= {}
        property.delete("properties")
        property.delete("required")
      else
        property.delete("properties")
        property.delete("required")
        property.delete("items")
      end

      property
    end
  end
end
