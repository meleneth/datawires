# frozen_string_literal: true

class DraftCommitPreflight
  Warning = Data.define(:code, :title, :message)

  UNSUPPORTED_SCHEMA_DECLARATION = "unsupported_schema_declaration"

  def initialize(draft:, confirmed_warning_codes: [])
    @draft = draft
    @confirmed_warning_codes = Array(confirmed_warning_codes).map(&:to_s)
  end

  def warnings
    @warnings ||= [
      unsupported_schema_declaration_warning
    ].compact
  end

  def blocked?
    unconfirmed_warnings.any?
  end

  def unconfirmed_warnings
    warnings.reject { |warning| confirmed?(warning) }
  end

  private

  attr_reader :draft, :confirmed_warning_codes

  def confirmed?(warning)
    confirmed_warning_codes.include?(warning.code)
  end

  def unsupported_schema_declaration_warning
    body = draft.body
    return unless body.is_a?(Hash)
    return unless body["$schema"].present?
    return if body["$schema"] == Document::JSON_SCHEMA_2020_12

    Warning.new(
      code: UNSUPPORTED_SCHEMA_DECLARATION,
      title: "Unsupported schema declaration",
      message: "This document declares an unsupported JSON Schema dialect. Committing it will treat the document as not_schema and schema-based affordances may degrade."
    )
  end
end
