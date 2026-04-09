module Editors
  # frozen_string_literal: true

  class DocumentScalarFieldComponent < ViewComponent::Base
    attr_reader :row, :widget, :show_label

    def initialize(row:, widget: "auto", show_label: true)
      @row = row
      @widget = widget
      @show_label = show_label
    end

    def field_id
      "field_#{row.ptr.parameterize(separator: '_')}"
    end

    def effective_widget
      return widget.to_sym unless widget.to_s == "auto"

      case row.input_kind
      when :checkbox
        :checkbox
      when :number
        :number
      when :select
        :select
      else
        :text
      end
    end
  end
end
