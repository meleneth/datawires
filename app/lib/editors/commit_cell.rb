# frozen_string_literal: true

class DocumentEditorCommitCell
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

  def span_class
    "col-span-#{span || 12}"
  end
end
