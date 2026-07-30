# frozen_string_literal: true

module Boards
  class MeetingCollection
    Result = DocumentCollection::Result

    def self.call(board:, section:)
      new(board:, section:).call
    end

    def initialize(board:, section:)
      raise ArgumentError, "board must be a Board" unless board.is_a?(Board)
      raise ArgumentError, "section must be a Boards::Projection::Entry" unless section.is_a?(Boards::Projection::Entry)

      @board = board
      @section = section
    end

    def call
      meetings = Meeting
        .includes(:event_stream, meeting_document: :head_revision)
        .where(meeting_document: { domain_id: board.schema_wrapper.domain.id })
        .select { |meeting| statuses.include?(meeting.projection.status) }
        .sort_by { |meeting| sortable_value(meeting) }
      meetings.reverse! if order.fetch("direction", "asc") == "desc"

      Result.new(
        documents: meetings.first(config.fetch("limit", 20)).map(&:meeting_document),
        view_affordance: nil,
        empty_state: config["empty_state"].presence || "No meetings found.",
        error: nil
      )
    end

    private

    attr_reader :board, :section

    def config
      section.config
    end

    def statuses
      config.fetch("statuses")
    end

    def order
      config.fetch("order", {})
    end

    def sortable_value(meeting)
      value = case order.fetch("by", "scheduled_at")
      when "scheduled_at" then meeting.meeting_document.body["scheduled_at"]
      when "created_at" then meeting.created_at
      when "updated_at" then meeting.updated_at
      end

      [ value.nil? ? 1 : 0, value.to_s, meeting.id ]
    end
  end
end
