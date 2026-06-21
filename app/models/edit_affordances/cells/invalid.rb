# frozen_string_literal: true

module EditAffordances
  module Cells
    class Invalid
      attr_reader :cell_data, :diagnostic, :span

      def initialize(cell_data:, diagnostic:, span: nil)
        @cell_data = cell_data
        @diagnostic = diagnostic
        @span = span
      end

      def field?
        false
      end

      def commit?
        false
      end

      def span_class(column_count)
        span_value = span.presence || column_count
        "col-span-#{span_value}"
      end
    end
  end
end
