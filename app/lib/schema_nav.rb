# frozen_string_literal: true

class SchemaNav
  def initialize(schema_hash)
    @schema = schema_hash
  end

  def subschema_at(path)
    JsonPtr.fetch(@schema, SchemaPath.new(path).json_ptr, default: {})
  end

  def properties_at(path)
    subschema_at(path).fetch("properties", {})
  end

  def object_schema?(subschema)
    return false unless subschema.is_a?(Hash)

    t = subschema["type"]
    t == "object" ||
      (t.is_a?(Array) && t.include?("object")) ||
      subschema.key?("properties")
  end

  def property_keys_at(path)
    properties_at(path).keys.sort
  end

  def object_keys_at(path)
    properties_at(path).select { |_k, v| object_schema?(v) }.keys.sort
  end

  def child_path(parent_path, child_key)
    SchemaPath.new(parent_path).child(child_key).to_s
  end
end
