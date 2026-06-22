# frozen_string_literal: true

module EditAffordances
  module Cells
    class Navigation
      attr_reader :span, :target_screen_id, :label

      def initialize(span:, target_screen_id:, label:)
        @span = span
        @target_screen_id = target_screen_id
        @label = label
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
