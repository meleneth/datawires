# frozen_string_literal: true

class DocumentEditorFieldCell
  attr_reader :projection_row, :span, :widget, :label

  def initialize(projection_row:, span:, widget:, label:)
    @projection_row = projection_row
    @span = span
    @widget = widget
    @label = label
  end

  def field?
    true
  end

  def commit?
    false
  end

  def span_class
    "col-span-#{span || 12}"
  end
end
