# app/lib/document_projection_row.rb
# frozen_string_literal: true

class DocumentProjectionRow
  def initialize(projection:, name:)
    @projection = projection
    @name = name
  end

  attr_reader :name

  def schema
    @schema ||= @projection.child_schema(name) || {}
  end

  def type
    schema["type"] || "(no type)"
  end

  def required?
    @projection.child_required?(name)
  end

  def present?
    @projection.child_present?(name)
  end

  def value
    @projection.child_value(name)
  end

  def openable?
    type == "object" || type == "array" || value.is_a?(Hash) || value.is_a?(Array)
  end

  def path
    @projection.path.child(name)
  end

  def value_label
    return "missing" unless present?
    return "present" if value.is_a?(Hash) || value.is_a?(Array)

    value.inspect
  end
end
