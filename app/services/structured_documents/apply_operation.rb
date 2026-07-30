# frozen_string_literal: true

module StructuredDocuments
  class ApplyOperation
    class Invalid < StandardError; end

    Result = Data.define(:content, :operation)
    TYPES = %w[replace].freeze

    def self.call(content:, operation:, current_version:)
      new(content:, operation:, current_version:).call
    end

    def initialize(content:, operation:, current_version:)
      raise Invalid, "Structured content must be an object." unless content.is_a?(Hash)
      raise Invalid, "Amendment operation must be an object." unless operation.is_a?(Hash)

      @content = content
      @operation = operation
      @current_version = current_version
    end

    def call
      validate!
      Result.new(
        content: UuidTools.deep_freeze(apply_replace),
        operation: UuidTools.deep_freeze(operation.deep_dup)
      )
    rescue ArgumentError, TypeError => e
      raise Invalid, e.message
    end

    private

    attr_reader :content, :operation, :current_version

    def validate!
      raise Invalid, "Amendment operation version must be 1." unless operation["version"] == 1
      raise Invalid, "Amendment operation type is not supported." unless TYPES.include?(operation["type"])
      unless operation["base_version"] == current_version
        raise Invalid, "Amendment operation is based on a stale pending-question version."
      end
      raise Invalid, "Amendment operation path must be a JSON Pointer." unless operation["path"].is_a?(String)
      raise Invalid, "Replace operation requires a value." unless operation.key?("value")

      target = Ptr::Json.new(body: content, ptr: operation["path"])
      raise Invalid, "Amendment operation target does not exist." unless target.present?
    end

    def apply_replace
      JsonPtr.set(content.deep_dup, operation.fetch("path"), operation["value"].deep_dup)
    end
  end
end
