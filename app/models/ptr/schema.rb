# frozen_string_literal: true

module Ptr
  class Schema
    class InvalidPtrError < ArgumentError; end
    class InvalidTraversalError < StandardError; end

    ROOT = "".freeze

    attr_reader :schema, :ptr

    def initialize(schema:, ptr: ROOT)
      @schema = schema.is_a?(Hash) ? schema : {}
      @ptr = normalize_ptr(ptr)
    end

    def self.root(schema:)
      new(schema:, ptr: ROOT)
    end

    def self.from_json(json:, schema:)
      new(schema:, ptr: path_for_json_ptr(json.ptr, schema:))
    end

    def root?
      ptr == ROOT
    end

    def pointer
      @pointer ||= JsonPtr::Pointer.parse(ptr)
    end

    def tokens
      pointer.tokens.map(&:unescaped)
    end

    def name
      tokens.last
    end

    def node
      JsonPtr.get(schema, ptr)
    rescue StandardError
      nil
    end

    def at(ptr)
      self.class.new(schema:, ptr:)
    end

    def parent
      return nil if root?

      self.class.new(schema:, ptr: parent_ptr)
    end

    def object?
      object_schema?(node)
    end

    def array?
      array_schema?(node)
    end

    def scalar?
      !object? && !array?
    end

    def array_element?
      return false if root?

      parent&.array?
    end

    def object_property?
      return false if root?

      parent&.object?
    end

    def children
      current = node

      if object_schema?(current)
        properties = current["properties"]
        return [] unless properties.is_a?(Hash)

        properties.keys.sort.map { |key| child_property(key) }
      elsif array_schema?(current)
        items = current["items"]
        return [] unless items.present?

        [ child_item ]
      else
        []
      end
    end

    def child_property(name)
      raise InvalidTraversalError, "current node is not an object schema" unless object?

      self.class.new(schema:, ptr: pointer.child("properties").child(name.to_s).to_s)
    end

    def child_item
      raise InvalidTraversalError, "current node is not an array schema" unless array?

      self.class.new(schema:, ptr: pointer.child("items").to_s)
    end

    def to_s
      ptr
    end

    def ==(other)
      other.is_a?(self.class) && other.schema.equal?(schema) && other.ptr == ptr
    end
    alias eql? ==

    def hash
      [ self.class, schema.object_id, ptr ].hash
    end

    private

    def normalize_ptr(raw)
      JsonPtr::Pointer.parse(raw.nil? ? ROOT : raw).to_s
    rescue ArgumentError => e
      raise InvalidPtrError, e.message
    end

    def parent_ptr
      tokens[0...-1].reduce(JsonPtr::Pointer.parse(ROOT)) do |memo, token|
        memo.child(token)
      end.to_s
    end

    def object_schema?(candidate)
      candidate.is_a?(Hash) && (
        candidate["type"] == "object" ||
        candidate["properties"].is_a?(Hash)
      )
    end

    def array_schema?(candidate)
      candidate.is_a?(Hash) && (
        candidate["type"] == "array" ||
        candidate.key?("items")
      )
    end

    def self.path_for_json_ptr(json_ptr, schema:)
      resolver = Documents::SchemaResolver.new(root_schema: schema)
      current = resolver.resolve(schema)
      schema_ptr = JsonPtr::Pointer.parse(ROOT)

      JsonPtr::Pointer.parse(json_ptr).tokens.each do |token|
        current = resolver.resolve(current)

        if object_schema?(current)
          properties = current["properties"]
          unless properties.is_a?(Hash) && properties.key?(token.unescaped)
            raise InvalidTraversalError, "property #{token.unescaped.inspect} not found"
          end

          schema_ptr = schema_ptr.child("properties").child(token.unescaped)
          current = properties[token.unescaped]
          next
        end

        if array_schema?(current)
          unless integer_token?(token.unescaped)
            raise InvalidTraversalError, "array index expected, got #{token.unescaped.inspect}"
          end

          items = current["items"]
          if items.blank?
            raise InvalidTraversalError, "array schema missing items for #{json_ptr}"
          end

          schema_ptr = schema_ptr.child("items")
          current = items
          next
        end

        raise InvalidTraversalError, "cannot traverse #{token.unescaped.inspect} through #{current.inspect}"
      end

      resolver.resolve(current)
      schema_ptr.to_s
    end

    def self.object_schema?(candidate)
      candidate.is_a?(Hash) && (
        candidate["type"] == "object" ||
        candidate["properties"].is_a?(Hash)
      )
    end

    def self.array_schema?(candidate)
      candidate.is_a?(Hash) && (
        candidate["type"] == "array" ||
        candidate.key?("items")
      )
    end

    def self.integer_token?(token)
      Integer(token, 10)
      true
    rescue ArgumentError, TypeError
      false
    end
  end
end
