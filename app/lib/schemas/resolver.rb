module Schemas
  # frozen_string_literal: true

  class Resolver
    def initialize(schema_hash)
      @schema = schema_hash
    end

    # Given an INSTANCE pointer (into the document), resolve the applicable subschema.
    # v1: only supports object properties traversal (your current behavior).
    def subschema_for_instance_ptr(instance_ptr)
      tokens = JsonPtr::Pointer.parse(instance_ptr.to_s).tokens.map(&:unescaped)
      cur = @schema

      tokens.each do |key|
        cur = cur.fetch("properties", {}).fetch(key) { return {} }
      end

      cur.is_a?(Hash) ? cur : {}
    end

    def properties_for_instance_ptr(instance_ptr)
      subschema_for_instance_ptr(instance_ptr).fetch("properties", {})
    end

    def object_schema?(subschema)
      return false unless subschema.is_a?(Hash)

      t = subschema["type"]
      return true if t == "object"
      return true if t.is_a?(Array) && t.include?("object")
      return true if subschema.key?("properties")
      false
    end

    # Child keys that themselves are objects (useful for nav/ribbon trees)
    def object_keys_for_instance_ptr(instance_ptr)
      properties_for_instance_ptr(instance_ptr)
        .select { |_k, v| object_schema?(v) }
        .keys
        .sort
    end

    def child_instance_ptr(parent_ptr, child_key)
      JsonPtr::Pointer.parse(parent_ptr.to_s).child(child_key).to_s
    end
  end
end
