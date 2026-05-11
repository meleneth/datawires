# frozen_string_literal: true

module Ptr
  class Cursor
    attr_reader :json, :schema

    def initialize(json:, schema:)
      @json = json
      @schema = schema
    end

    def self.for(body:, schema_body:, ptr: Ptr::Json::ROOT)
      json = Ptr::Json.new(body:, ptr:)
      schema = Ptr::Schema.from_json(json:, schema: schema_body)

      new(json:, schema:)
    end

    def self.from_source(source:, path:)
      ptr = path.is_a?(Documents::Path) ? path.to_s : path

      self.for(
        body: source.body,
        schema_body: source.schema_document.body,
        ptr:
      )
    end

    def ptr
      json.ptr
    end

    def schema_ptr
      schema.ptr
    end

    def root?
      json.root?
    end

    def name
      json.name
    end

    def path
      @path ||= Documents::Path.new(ptr)
    end

    def value
      json.value
    end

    def schema_node
      schema.node || {}
    end

    def at(ptr)
      self.class.for(
        body: json.body,
        schema_body: schema.schema,
        ptr:
      )
    end

    def parent
      return nil if root?

      parent_json = json.parent

      self.class.new(
        json: parent_json,
        schema: Ptr::Schema.from_json(json: parent_json, schema: schema.schema)
      )
    end

    def child(segment)
      child_json = json.child(segment)

      self.class.new(
        json: child_json,
        schema: Ptr::Schema.from_json(json: child_json, schema: schema.schema)
      )
    end

    def present?
      json.present?
    end

    def object?
      schema.object? || value.is_a?(Hash)
    end

    def array?
      schema.array? || value.is_a?(Array)
    end

    def composite?
      object? || array?
    end

    def openable?
      object? || array?
    end

    def scalar?
      !object? && !array?
    end

    def array_element?
      json.array_element?
    end

    def object_property?
      json.object_property?
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

    def seed_value
      Documents::SeedValue.for(schema_node)
    end

    def seed_item_value
      return nil unless array?

      Documents::SeedValue.for(schema_node["items"])
    end

    private

    def inferred_type
      return "object" if value.is_a?(Hash)
      return "array" if value.is_a?(Array)

      nil
    end
  end
end
