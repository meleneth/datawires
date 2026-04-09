# frozen_string_literal: true

module Editors
  class DocumentScalarFieldComponent < ApplicationComponent
    attr_reader :row, :widget, :show_label, :edit_affordance_id, :current_path

    def initialize(row:, widget: "auto", show_label: true, edit_affordance_id: nil, current_path: nil)
      @row = row
      @widget = widget
      @show_label = show_label
      @edit_affordance_id = edit_affordance_id
      @current_path = current_path
    end

    def field_id
      "field_#{row.ptr.parameterize(separator: '_')}"
    end

    def effective_widget
      return widget.to_sym unless widget.to_s == "auto"

      case row.input_kind
      when :checkbox then :checkbox
      when :number then :number
      when :select then :select
      else
        :text
      end
    end
  end
end
