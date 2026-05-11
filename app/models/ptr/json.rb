# frozen_string_literal: true

module Ptr
  class Json
    class InvalidPtrError < ArgumentError; end

    ROOT = "".freeze

    attr_reader :body, :ptr

    def initialize(body:, ptr: ROOT)
      @body = body
      @ptr = normalize_ptr(ptr)
    end

    def self.root(body:)
      new(body:, ptr: ROOT)
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

    def value
      JsonPtr.get(body, ptr)
    end

    def at(ptr)
      self.class.new(body:, ptr:)
    end

    def child(segment)
      self.class.new(body:, ptr: pointer.child(segment.to_s).to_s)
    end

    def parent
      return nil if root?

      self.class.new(body:, ptr: parent_ptr)
    end

    def present?
      return true if root?

      parent_value = parent&.value

      if array_element?
        return false unless parent_value.is_a?(Array)

        index = Integer(name, 10)
        index >= 0 && index < parent_value.length
      else
        return false unless parent_value.is_a?(Hash)
        return false if name.nil?

        parent_value.key?(name) || parent_value.key?(name.to_sym)
      end
    rescue ArgumentError, TypeError
      false
    end

    def object?
      value.is_a?(Hash)
    end

    def array?
      value.is_a?(Array)
    end

    def scalar?
      !object? && !array?
    end

    def composite?
      object? || array?
    end

    def array_element?
      return false if root?

      Integer(name, 10)
      parent&.value.is_a?(Array)
    rescue ArgumentError, TypeError
      false
    end

    def object_property?
      return false if root?
      return false if array_element?

      parent&.value.is_a?(Hash)
    end

    def children
      if object?
        value.keys.map(&:to_s).sort.map { |key| child(key) }
      elsif array?
        value.each_index.map { |index| child(index.to_s) }
      else
        []
      end
    end

    def to_s
      ptr
    end

    def ==(other)
      other.is_a?(self.class) && other.body.equal?(body) && other.ptr == ptr
    end
    alias eql? ==

    def hash
      [ self.class, body.object_id, ptr ].hash
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
  end
end
