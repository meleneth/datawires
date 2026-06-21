# frozen_string_literal: true

module EditAffordances
  module Cells
    class Field
      attr_reader :cursor, :span, :widget, :label, :item_rows, :help, :placeholder

      def initialize(cursor:, span:, widget:, label:, item_rows: nil, help: nil, placeholder: nil)
        @cursor = cursor
        @span = span
        @widget = widget
        @label = label
        @item_rows = item_rows
        @help = help
        @placeholder = placeholder
      end

      delegate :name,
               :path,
               :ptr,
               :schema_node,
               :enum_values,
               :type,
               :required?,
               :present?,
               :value,
               :object?,
               :array?,
               :composite?,
               :openable?,
               :scalar?,
               :array_element?,
               :object_property?,
               :input_kind,
               :field_value,
               :checkbox_value,
               :value_label,
               to: :cursor

      def field?
        true
      end

      def commit?
        false
      end

      def span_class(column_count)
        span_value = span.presence || column_count
        "col-span-#{span_value}"
      end

      def widget_kind
        widget == "auto" ? input_kind : widget.to_sym
      end
    end
  end
end
