# frozen_string_literal: true

module Boards
  class BodyValidator
    VERSION = 1
    SECTION_KINDS = %w[document_collection summary].freeze
    ACTION_KINDS = %w[open_edit_affordance invoke_command].freeze

    attr_reader :errors

    def initialize(body)
      @body = body
      @errors = []
      validate
    end

    def valid?
      errors.empty?
    end

    private

    attr_reader :body

    def validate
      unless body.is_a?(Hash)
        errors << "body must be an object"
        return
      end

      errors << "version must be #{VERSION}" unless body["version"] == VERSION
      errors << "title must be a non-empty string" unless non_empty_string?(body["title"])
      errors << "description must be a string" unless body["description"].nil? || body["description"].is_a?(String)
      validate_entries("sections", SECTION_KINDS)
      validate_entries("actions", ACTION_KINDS)
      validate_layout
    end

    def validate_entries(key, kinds)
      entries = body[key]
      unless entries.is_a?(Array)
        errors << "#{key} must be an array"
        return
      end

      entries.each_with_index do |entry, index|
        unless entry.is_a?(Hash)
          errors << "#{key}[#{index}] must be an object"
          next
        end

        errors << "#{key}[#{index}].id must be a non-empty string" unless non_empty_string?(entry["id"])
        errors << "#{key}[#{index}].title must be a non-empty string" unless non_empty_string?(entry["title"])
        errors << "#{key}[#{index}].kind must be one of: #{kinds.join(", ")}" unless kinds.include?(entry["kind"])
      end

      duplicate_ids = entries.filter_map { |entry| entry["id"] if entry.is_a?(Hash) }.tally.select { |_id, count| count > 1 }.keys
      errors << "#{key} ids must be unique: #{duplicate_ids.join(", ")}" if duplicate_ids.any?
    end

    def validate_layout
      return if body["layout"].nil?
      return if body["layout"].is_a?(Hash)

      errors << "layout must be an object"
    end

    def non_empty_string?(value)
      value.is_a?(String) && value.present?
    end
  end
end
