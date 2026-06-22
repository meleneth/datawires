# frozen_string_literal: true

module EditAffordances
  class BodyValidator
    SUPPORTED_WIDGETS = %w[array auto checkbox number select text textarea].freeze
    SCREEN_MODES = %w[page full_width].freeze
    COMMIT_MODES = %w[immediate review_screen].freeze
    MESSAGE_MODES = %w[hidden inline_optional inline_required].freeze
    COLLECTION_BEHAVIORS = %w[list_open].freeze
    COLLECTION_PRESENTATIONS = %w[cards list table].freeze
    COLLECTION_CREATIONS = %w[append_and_open inline_blank_form new_screen].freeze
    COLLECTION_NAVIGATIONS = %w[open_item].freeze
    COLLECTION_DELETE_POLICIES = %w[disabled enabled].freeze
    COLLECTION_REORDER_POLICIES = %w[disabled enabled].freeze
    COLLECTION_BINDING_KINDS = %w[property value_label none].freeze
    WIDTHS = %w[narrow medium large full].freeze
    SPAN_RANGE = (1..12).freeze

    attr_reader :body

    def initialize(body)
      @body = body
    end

    def errors
      @errors ||= validate
    end

    def valid?
      errors.empty?
    end

    private

    def validate
      errors = []
      return [ "body must be a JSON object" ] unless body.is_a?(Hash)

      validate_version(errors)
      validate_enum(errors, body, "commit_mode", COMMIT_MODES, "commit_mode")
      validate_enum(errors, body, "width", WIDTHS, "width")
      validate_screen(errors)
      validate_start_screen(errors)
      subform_ids = validate_subforms(errors)
      validate_screens(errors, subform_ids: subform_ids)
      validate_body_rows(errors) unless body.key?("screens")

      errors
    end

    def validate_version(errors)
      version = body["version"]

      if version.blank?
        errors << "version is required"
      elsif !integer?(version)
        errors << "version must be an integer"
      elsif !EditAffordances::Versions::SUPPORTED.include?(version.to_i)
        errors << "version #{version.inspect} is not supported"
      end
    end

    def validate_screen(errors)
      screen = body["screen"]
      return if screen.blank?

      unless screen.is_a?(Hash)
        errors << "screen must be an object"
        return
      end

      validate_enum(errors, screen, "mode", SCREEN_MODES, "screen.mode")
      validate_positive_integer(errors, screen, "columns", "screen.columns")
      validate_span(errors, screen, "default_span", "screen.default_span")
      validate_enum(errors, screen, "width", WIDTHS, "screen.width")
      validate_enum(errors, screen, "commit_mode", COMMIT_MODES, "screen.commit_mode")
    end

    def validate_start_screen(errors)
      return unless body.key?("start_screen")
      return if body["start_screen"].is_a?(String) && body["start_screen"].present?

      errors << "start_screen must be a string"
    end

    def validate_subforms(errors)
      return [] unless body.key?("subforms")

      subforms = body["subforms"]
      unless subforms.is_a?(Array)
        errors << "subforms must be an array"
        return []
      end

      subform_ids = []
      subforms.each_with_index do |subform, subform_index|
        subform_ids << subform["id"] if subform.is_a?(Hash) && subform["id"].is_a?(String)
      end

      subforms.each_with_index do |subform, subform_index|
        validate_subform_definition(errors, subform, subform_index)
      end

      duplicate_ids(subform_ids).each { |id| errors << "subforms id #{id.inspect} must be unique" }
      subform_ids
    end

    def validate_subform_definition(errors, subform, subform_index)
      path = "subforms/#{subform_index}"

      unless subform.is_a?(Hash)
        errors << "#{path} must be an object"
        return
      end

      errors << "#{path}/id is required" unless subform["id"].is_a?(String) && subform["id"].present?
      validate_binding(errors, subform["root_binding"], "#{path}/root_binding") if subform.key?("root_binding")
      validate_rows(errors, key: "rows", path: "#{path}/rows", object: subform)
    end

    def validate_screens(errors, subform_ids:)
      return unless body.key?("screens")

      screens = body["screens"]
      unless screens.is_a?(Array)
        errors << "screens must be an array"
        return
      end

      errors << "screens must contain at least one screen" if screens.empty?

      screen_ids = []
      screens.each_with_index do |screen, screen_index|
        screen_ids << screen["id"] if screen.is_a?(Hash) && screen["id"].is_a?(String)
      end

      screens.each_with_index do |screen, screen_index|
        validate_screen_definition(errors, screen, screen_index, screen_ids: screen_ids, subform_ids: subform_ids)
      end

      duplicate_ids(screen_ids).each { |id| errors << "screens id #{id.inspect} must be unique" }

      return unless body["start_screen"].present? && !screen_ids.include?(body["start_screen"])

      errors << "start_screen must match a screen id"
    end

    def validate_screen_definition(errors, screen, screen_index, screen_ids:, subform_ids:)
      path = "screens/#{screen_index}"

      unless screen.is_a?(Hash)
        errors << "#{path} must be an object"
        return
      end

      errors << "#{path}/id is required" unless screen["id"].is_a?(String) && screen["id"].present?
      validate_string(errors, screen, "title", "#{path}/title")
      validate_positive_integer(errors, screen, "columns", "#{path}/columns")
      validate_span(errors, screen, "default_span", "#{path}/default_span")
      validate_enum(errors, screen, "width", WIDTHS, "#{path}/width")
      validate_enum(errors, screen, "mode", SCREEN_MODES, "#{path}/mode")
      validate_enum(errors, screen, "commit_mode", COMMIT_MODES, "#{path}/commit_mode")
      validate_binding(errors, screen["root_binding"], "#{path}/root_binding") if screen.key?("root_binding")
      validate_screen_subform(errors, screen, "#{path}/subform", subform_ids: subform_ids)

      if screen.key?("rows")
        validate_rows(errors, key: "rows", path: "#{path}/rows", object: screen, screen_ids: screen_ids)
      elsif !screen.key?("subform")
        errors << "#{path}/rows must be an array"
      end
    end

    def validate_screen_subform(errors, screen, path, subform_ids:)
      return unless screen.key?("subform")

      subform_id = screen["subform"]
      if !subform_id.is_a?(String) || subform_id.blank?
        errors << "#{path} must be a string"
      elsif !subform_ids.include?(subform_id)
        errors << "#{path} must match a subform id"
      end
    end

    def validate_body_rows(errors)
      validate_rows(errors, key: "rows", path: "rows", object: body)
    end

    def validate_rows(errors, key: "rows", path: "rows", object: body, screen_ids: nil)
      rows = object[key]

      unless rows.is_a?(Array)
        errors << "#{path} must be an array"
        return
      end

      rows.each_with_index do |row, row_index|
        unless row.is_a?(Array)
          errors << "#{path}/#{row_index} must be an array"
          next
        end

        errors << "#{path}/#{row_index} must contain at least one cell" if row.empty?
        row.each_with_index { |cell, cell_index| validate_cell(errors, cell, "#{path}/#{row_index}/#{cell_index}", screen_ids: screen_ids) }
      end
    end

    def validate_cell(errors, cell, path, screen_ids: nil)
      unless cell.is_a?(Hash)
        errors << "#{path} must be an object"
        return
      end

      if cell["kind"] == "commit"
        validate_commit_cell(errors, cell, path)
      elsif cell["kind"] == "navigation"
        validate_navigation_cell(errors, cell, path, screen_ids: screen_ids)
      elsif cell.key?("binding")
        validate_field_cell(errors, cell, path, screen_ids: screen_ids)
      else
        errors << "#{path} must be a field, navigation, or commit cell"
      end
    end

    def validate_field_cell(errors, cell, path, screen_ids:)
      validate_binding(errors, cell["binding"], "#{path}/binding")
      validate_span(errors, cell, "span", "#{path}/span")
      validate_enum(errors, cell, "widget", SUPPORTED_WIDGETS, "#{path}/widget")
      validate_string(errors, cell, "help", "#{path}/help")
      validate_string(errors, cell, "placeholder", "#{path}/placeholder")
      validate_display(errors, cell, "#{path}/display")
      validate_collection(errors, cell, "#{path}/collection", screen_ids: screen_ids)

      return unless cell.key?("label") && !boolean?(cell["label"])

      errors << "#{path}/label must be a boolean"
    end

    def validate_commit_cell(errors, cell, path)
      validate_span(errors, cell, "span", "#{path}/span")
      validate_enum(errors, cell, "message_mode", MESSAGE_MODES, "#{path}/message_mode")
      validate_enum(errors, cell, "commit_mode", COMMIT_MODES, "#{path}/commit_mode")
    end

    def validate_navigation_cell(errors, cell, path, screen_ids:)
      validate_span(errors, cell, "span", "#{path}/span")
      validate_string(errors, cell, "label", "#{path}/label")

      target_screen = cell["target_screen"]
      if !target_screen.is_a?(String) || target_screen.blank?
        errors << "#{path}/target_screen is required"
      elsif screen_ids && !screen_ids.include?(target_screen)
        errors << "#{path}/target_screen must match a screen id"
      end
    end

    def validate_binding(errors, binding, path)
      unless binding.is_a?(Hash)
        errors << "#{path} must be an object"
        return
      end

      errors << "#{path}/kind must be document_ptr" unless binding["kind"] == "document_ptr"

      ptr = binding["ptr"]
      errors << "#{path}/ptr is required" unless ptr.is_a?(String) && ptr.present?
    end

    def validate_display(errors, cell, path)
      return unless cell.key?("display")

      display = cell["display"]
      unless display.is_a?(Hash)
        errors << "#{path} must be an object"
        return
      end

      %w[compact readonly].each do |key|
        errors << "#{path}/#{key} must be a boolean" if display.key?(key) && !boolean?(display[key])
      end
    end

    def validate_collection(errors, cell, path, screen_ids:)
      return unless cell.key?("collection")

      collection = cell["collection"]
      unless collection.is_a?(Hash)
        errors << "#{path} must be an object"
        return
      end

      validate_enum(errors, collection, "behavior", COLLECTION_BEHAVIORS, "#{path}/behavior")
      validate_enum(errors, collection, "presentation", COLLECTION_PRESENTATIONS, "#{path}/presentation")
      validate_enum(errors, collection, "creation", COLLECTION_CREATIONS, "#{path}/creation")
      validate_enum(errors, collection, "navigation", COLLECTION_NAVIGATIONS, "#{path}/navigation")
      validate_enum(errors, collection, "delete", COLLECTION_DELETE_POLICIES, "#{path}/delete")
      validate_enum(errors, collection, "reorder", COLLECTION_REORDER_POLICIES, "#{path}/reorder")
      validate_collection_item_screen(errors, collection, "#{path}/item_screen", screen_ids: screen_ids)
      validate_collection_binding(errors, collection, "item_title", "#{path}/item_title")
      validate_collection_binding(errors, collection, "item_subtitle", "#{path}/item_subtitle")
    end

    def validate_collection_item_screen(errors, collection, path, screen_ids:)
      return unless collection.key?("item_screen")

      item_screen = collection["item_screen"]
      if !item_screen.is_a?(String) || item_screen.blank?
        errors << "#{path} must be a string"
      elsif screen_ids && !screen_ids.include?(item_screen)
        errors << "#{path} must match a screen id"
      end
    end

    def validate_collection_binding(errors, collection, key, path)
      return unless collection.key?(key)

      binding = collection[key]
      unless binding.is_a?(Hash)
        errors << "#{path} must be an object"
        return
      end

      errors << "#{path}/kind is required" unless binding.key?("kind")
      validate_enum(errors, binding, "kind", COLLECTION_BINDING_KINDS, "#{path}/kind")

      if binding["kind"] == "property"
        errors << "#{path}/name must be a string" unless binding["name"].is_a?(String) && binding["name"].present?
      elsif binding.key?("name")
        errors << "#{path}/name is only supported for property bindings"
      end
    end

    def validate_positive_integer(errors, object, key, path)
      return unless object.key?(key)
      return if integer?(object[key]) && object[key].to_i.positive?

      errors << "#{path} must be a positive integer"
    end

    def validate_span(errors, object, key, path)
      return unless object.key?(key)

      unless integer?(object[key]) && object[key].to_i.positive?
        errors << "#{path} must be a positive integer"
        return
      end

      return if SPAN_RANGE.cover?(object[key].to_i)

      errors << "#{path} must be between #{SPAN_RANGE.begin} and #{SPAN_RANGE.end}"
    end

    def validate_enum(errors, object, key, allowed, path)
      return unless object.key?(key)
      return if allowed.include?(object[key])

      errors << "#{path} must be one of: #{allowed.join(', ')}"
    end

    def validate_string(errors, object, key, path)
      return unless object.key?(key)
      return if object[key].is_a?(String)

      errors << "#{path} must be a string"
    end

    def integer?(value)
      value.is_a?(Integer) || value.to_s.match?(/\A\d+\z/)
    end

    def boolean?(value)
      value == true || value == false
    end

    def duplicate_ids(ids)
      ids.tally.select { |_id, count| count > 1 }.keys
    end
  end
end
