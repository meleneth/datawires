# frozen_string_literal: true

module EditAffordances
  class BodyValidator
    SUPPORTED_WIDGETS = %w[array auto checkbox number select text textarea].freeze
    SCREEN_MODES = %w[page full_width].freeze
    COMMIT_MODES = %w[immediate review_screen].freeze
    MESSAGE_MODES = %w[hidden inline_optional inline_required].freeze

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
      validate_screen(errors)
      validate_rows(errors)

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
      validate_positive_integer(errors, screen, "default_span", "screen.default_span")
      validate_enum(errors, screen, "commit_mode", COMMIT_MODES, "screen.commit_mode")
    end

    def validate_rows(errors)
      rows = body["rows"]

      unless rows.is_a?(Array)
        errors << "rows must be an array"
        return
      end

      rows.each_with_index do |row, row_index|
        unless row.is_a?(Array)
          errors << "rows/#{row_index} must be an array"
          next
        end

        errors << "rows/#{row_index} must contain at least one cell" if row.empty?
        row.each_with_index { |cell, cell_index| validate_cell(errors, cell, row_index, cell_index) }
      end
    end

    def validate_cell(errors, cell, row_index, cell_index)
      path = "rows/#{row_index}/#{cell_index}"

      unless cell.is_a?(Hash)
        errors << "#{path} must be an object"
        return
      end

      if cell["kind"] == "commit"
        validate_commit_cell(errors, cell, path)
      elsif cell.key?("binding")
        validate_field_cell(errors, cell, path)
      else
        errors << "#{path} must be a field or commit cell"
      end
    end

    def validate_field_cell(errors, cell, path)
      validate_binding(errors, cell["binding"], "#{path}/binding")
      validate_positive_integer(errors, cell, "span", "#{path}/span")
      validate_enum(errors, cell, "widget", SUPPORTED_WIDGETS, "#{path}/widget")
      validate_string(errors, cell, "help", "#{path}/help")
      validate_string(errors, cell, "placeholder", "#{path}/placeholder")

      return unless cell.key?("label") && !boolean?(cell["label"])

      errors << "#{path}/label must be a boolean"
    end

    def validate_commit_cell(errors, cell, path)
      validate_positive_integer(errors, cell, "span", "#{path}/span")
      validate_enum(errors, cell, "message_mode", MESSAGE_MODES, "#{path}/message_mode")
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

    def validate_positive_integer(errors, object, key, path)
      return unless object.key?(key)
      return if integer?(object[key]) && object[key].to_i.positive?

      errors << "#{path} must be a positive integer"
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
  end
end
