# frozen_string_literal: true

module EditAffordances
  module Cells
    class Commit
      attr_reader :span, :message_mode

      def initialize(span:, message_mode:)
        @span = span
        @message_mode = message_mode
      end

      def field?
        false
      end

      def commit?
        true
      end

      def span_class(column_count)
        span_value = span.presence || column_count
        "col-span-#{span_value}"
      end
    end
  end
end
