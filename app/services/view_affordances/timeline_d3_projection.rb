# frozen_string_literal: true

module ViewAffordances
  class TimelineD3Projection
    DEFAULT_SCHEMA_KEY = "timeline-event"
    include Rails.application.routes.url_helpers

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
          "url" => event_url_for(timeline_document),
          "relative_time" => relative_time,
          "event_type" => body["event_type"].to_s,
          "summary" => body["summary"].to_s,
          "participants" => participants_for(body)
        }
      end.sort_by { |event| [ event.fetch("relative_time"), event.fetch("title").to_s ] }
    end

    def timeline_documents
      return Document.none unless timeline_schema

      scope = document.domain.documents
        .includes(:head_revision)
        .with_head
        .where(schema_document: timeline_schema)
      return scope unless participant_filter?

      scope.where(id: filtered_timeline_document_ids)
    end

    def timeline_schema
      @timeline_schema ||= document.domain.documents.find_by(key: schema_key)
    end

    def event_url_for(timeline_document)
      return nil unless event_view_affordance

      document_view_affordance_path(timeline_document, event_view_affordance)
    end

    def event_view_affordance
      @event_view_affordance ||= timeline_schema&.schema_wrapper&.view_affordances&.order(:title)&.first
    end

    def filtered_timeline_document_ids
      return [] unless participant_filter?

      DocumentIndexEntry
        .where(
          schema_document_id: timeline_schema.id,
          index_type: DocumentIndexes::Rebuild::TIMELINE_PARTICIPANT_TYPE,
          key: participant_kind,
          value: participant_key
        )
        .pluck(:document_id)
    end

    def participant_filter?
      participant_kind.present? && participant_key.present?
    end

    def participant_kind
      config["participant_kind"].to_s.strip
    end

    def participant_key
      config["participant_key"].presence || document.key.to_s.strip
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
          "label" => participant_label(kind, key),
          "role" => participant["role"].to_s
        }
      end
    end

    def participant_label(kind, key)
      participant_labels.fetch([ kind, key ], key)
    end

    def participant_labels
      @participant_labels ||= begin
        pairs = timeline_documents.flat_map do |timeline_document|
          Array(timeline_document.body["participants"]).filter_map do |participant|
            next unless participant.is_a?(Hash)

            kind = participant["kind"].to_s.strip
            key = participant["key"].to_s.strip
            [ kind, key ] if kind.present? && key.present?
          end
        end.uniq
        schema_ids_by_key = document.domain.documents.where(key: pairs.map(&:first)).pluck(:key, :id).to_h

        DocumentIndexEntry
          .where(
            schema_document_id: schema_ids_by_key.values,
            index_type: DocumentIndexes::Rebuild::IDENTITY_TYPE,
            key: "document_key",
            value: pairs.map(&:second)
          )
          .each_with_object({}) do |entry, labels|
            schema_key = schema_ids_by_key.key(entry.schema_document_id)
            labels[[ schema_key, entry.value ]] = entry.label if schema_key.present?
          end
      end
    end
  end
end
