# frozen_string_literal: true

module Boards
  class BodyValidator
    VERSION = 1
    SECTION_KINDS = %w[document_collection summary].freeze
    ACTION_KINDS = %w[open_edit_affordance invoke_command].freeze
    FILTER_OPERATORS = %w[eq].freeze
    ORDER_FIELDS = %w[title key created_at updated_at body].freeze
    DIRECTIONS = %w[asc desc].freeze
    NAVIGATION_KINDS = %w[document view_affordance].freeze
    MAX_RESULT_LIMIT = 100

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
        validate_document_collection(entry, index) if key == "sections" && entry["kind"] == "document_collection"
      end

      duplicate_ids = entries.filter_map { |entry| entry["id"] if entry.is_a?(Hash) }.tally.select { |_id, count| count > 1 }.keys
      errors << "#{key} ids must be unique: #{duplicate_ids.join(", ")}" if duplicate_ids.any?
    end

    def validate_document_collection(entry, index)
      prefix = "sections[#{index}].config"
      config = entry["config"]
      unless config.is_a?(Hash)
        errors << "#{prefix} must be an object"
        return
      end

      errors << "#{prefix}.schema_key must be a non-empty string" unless non_empty_string?(config["schema_key"])
      validate_filters(config["filters"], prefix)
      validate_order(config["order"], prefix)
      validate_limit(config["limit"], prefix)
      validate_navigation(config, prefix)
      errors << "#{prefix}.empty_state must be a string" unless config["empty_state"].nil? || config["empty_state"].is_a?(String)
    end

    def validate_filters(filters, prefix)
      return if filters.nil?
      unless filters.is_a?(Array)
        errors << "#{prefix}.filters must be an array"
        return
      end

      filters.each_with_index do |filter, index|
        unless filter.is_a?(Hash)
          errors << "#{prefix}.filters[#{index}] must be an object"
          next
        end

        validate_pointer(filter["path"], "#{prefix}.filters[#{index}].path")
        operator = filter["operator"] || "eq"
        errors << "#{prefix}.filters[#{index}].operator must be one of: #{FILTER_OPERATORS.join(", ")}" unless FILTER_OPERATORS.include?(operator)
        errors << "#{prefix}.filters[#{index}].value is required" unless filter.key?("value")
      end
    end

    def validate_order(order, prefix)
      return if order.nil?
      unless order.is_a?(Hash)
        errors << "#{prefix}.order must be an object"
        return
      end

      field = order["by"]
      errors << "#{prefix}.order.by must be one of: #{ORDER_FIELDS.join(", ")}" unless ORDER_FIELDS.include?(field)
      direction = order["direction"] || "asc"
      errors << "#{prefix}.order.direction must be one of: #{DIRECTIONS.join(", ")}" unless DIRECTIONS.include?(direction)
      validate_pointer(order["path"], "#{prefix}.order.path") if field == "body"
    end

    def validate_limit(limit, prefix)
      return if limit.nil?
      return if limit.is_a?(Integer) && limit.between?(1, MAX_RESULT_LIMIT)

      errors << "#{prefix}.limit must be between 1 and #{MAX_RESULT_LIMIT}"
    end

    def validate_navigation(config, prefix)
      navigation = config["navigation"] || "document"
      errors << "#{prefix}.navigation must be one of: #{NAVIGATION_KINDS.join(", ")}" unless NAVIGATION_KINDS.include?(navigation)
      return unless navigation == "view_affordance"

      errors << "#{prefix}.view_affordance must be a non-empty string" unless non_empty_string?(config["view_affordance"])
    end

    def validate_pointer(pointer, field)
      JsonPtr::Pointer.parse(pointer)
    rescue ArgumentError
      errors << "#{field} must be a JSON Pointer"
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
