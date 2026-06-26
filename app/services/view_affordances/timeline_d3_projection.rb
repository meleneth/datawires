# frozen_string_literal: true

module ViewAffordances
  class TimelineD3Projection
    DEFAULT_SCHEMA_KEY = "timeline-event"

    def self.call(document:, view_affordance:)
      new(document:, view_affordance:).call
    end

    def initialize(document:, view_affordance:)
      @document = document
      @view_affordance = view_affordance
    end

    def call
      Projection.new(
        renderer: "timeline_d3",
        title: config["title"].presence || view_affordance.title,
        data: {
          "events" => events,
          "relative_time_label" => config["relative_time_label"].presence || "Relative time"
        }
      )
    end

    private

    attr_reader :document, :view_affordance

    def events
      timeline_documents.filter_map do |timeline_document|
        body = timeline_document.body
        relative_time = integer_or_nil(body["relative_time"])
        next if relative_time.nil?

        {
          "document_id" => timeline_document.id,
          "key" => timeline_document.key,
          "title" => body["title"].presence || timeline_document.title.presence || timeline_document.key,
          "relative_time" => relative_time,
          "event_type" => body["event_type"].to_s,
          "summary" => body["summary"].to_s,
          "participants" => participants_for(body)
        }
      end.sort_by { |event| [ event.fetch("relative_time"), event.fetch("title").to_s ] }
    end

    def timeline_documents
      return Document.none unless timeline_schema

      document.domain.documents
        .includes(:head_revision)
        .with_head
        .where(schema_document: timeline_schema)
    end

    def timeline_schema
      @timeline_schema ||= document.domain.documents.find_by(key: schema_key)
    end

    def schema_key
      config["schema_key"].presence || DEFAULT_SCHEMA_KEY
    end

    def config
      @config ||= view_affordance.body.fetch("config", {})
    end

    def integer_or_nil(value)
      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end

    def participants_for(body)
      Array(body["participants"]).filter_map do |participant|
        next unless participant.is_a?(Hash)

        kind = participant["kind"].to_s.strip
        key = participant["key"].to_s.strip
        next if kind.blank? || key.blank?

        {
          "kind" => kind,
          "key" => key,
          "role" => participant["role"].to_s
        }
      end
    end
  end
end
