# frozen_string_literal: true

module Editors
  class CommitCell
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
      "col-span-#{span || column_count}"
    end
  end
end
