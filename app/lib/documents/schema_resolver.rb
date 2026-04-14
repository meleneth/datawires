# frozen_string_literal: true

require "set"

module Documents
  class SchemaResolver
    class CircularRefError < StandardError; end
    class UnsupportedRefError < StandardError; end

    attr_reader :root_schema

    def initialize(root_schema:)
      @root_schema = root_schema.is_a?(Hash) ? root_schema : {}
    end

    def resolve(node, seen_refs: Set.new)
      current = node

      while current.is_a?(Hash) && current["$ref"].present?
        ref = current["$ref"]

        unless ref.start_with?("#/")
          raise UnsupportedRefError, "only internal $ref values are supported: #{ref.inspect}"
        end

        if seen_refs.include?(ref)
          raise CircularRefError, "circular $ref detected for #{ref.inspect}"
        end

        seen_refs = seen_refs.dup.add(ref)
        current = JsonPtr.get(root_schema, ref.delete_prefix("#"))
      end

      current
    end
  end
end
