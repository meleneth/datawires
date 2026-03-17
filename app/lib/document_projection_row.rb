# frozen_string_literal: true

class DocumentProjectionRow
  def initialize(projection:, name:)
    @projection = projection
    @name = name
  end

  attr_reader :name

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

  def composite?
    type == "object" || type == "array" || value.is_a?(Hash) || value.is_a?(Array)
  end

  def openable?
    composite?
  end

  def scalar?
    !composite?
  end

  def input_kind
    case type
    when "boolean"
      :checkbox
    when "integer", "number"
      :number
    else
      :text
    end
  end

  def field_value
    return value if present?

    case input_kind
    when :checkbox
      false
    else
      nil
    end
  end

  def path
    @projection.path.child(name)
  end

  def ptr
    path.document_ptr
  end

  def value_label
    return "missing" unless present?
    return "present" if composite?

    value.inspect
  end

  private

  def schema
    @schema ||= @projection.child_schema(name)
  end
end
