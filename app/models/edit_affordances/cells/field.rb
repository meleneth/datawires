# frozen_string_literal: true

module EditAffordances
  module Cells
    class Field
      attr_reader :cursor, :span, :widget, :label, :item_rows, :help, :placeholder, :display, :schema_entry

      def initialize(cursor:, span:, widget:, label:, item_rows: nil, help: nil, placeholder: nil, display: {}, schema_entry: nil)
        @cursor = cursor
        @span = span
        @widget = widget
        @label = label
        @item_rows = item_rows
        @help = help
        @placeholder = placeholder
        @display = display || {}
        @schema_entry = schema_entry
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
        widget == "auto" ? inferred_widget.to_sym : widget.to_sym
      end

      def inferred_widget
        schema_entry&.widget || input_kind.to_s
      end

      def default_label
        schema_entry&.label || cursor.name.to_s.humanize
      end

      def required?
        return schema_entry.required? unless schema_entry.nil?

        cursor.required?
      end
    end
  end
end
