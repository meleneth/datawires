# frozen_string_literal: true

module DocumentIndexes
  class Rebuild
    IDENTITY_TYPE = "identity"
    PARTY_MEMBER_TYPE = "party_member"
    TIMELINE_EVENT_TYPE = "timeline_event"
    TIMELINE_PARTICIPANT_TYPE = "timeline_participant"

    def self.call(document:, revision: document.head_revision)
      new(document:, revision:).call
    end

    def initialize(document:, revision:)
      raise ArgumentError, "document must be a Document" unless document.is_a?(Document)
      raise ArgumentError, "revision must be a Revision" unless revision.is_a?(Revision)

      @document = document
      @revision = revision
    end

    def call
      return if document.head_revision_id != revision.id
      return unless document.schema_document_id.present?

      DocumentIndexEntry.transaction do
        DocumentIndexEntry.where(document: document).delete_all
        entries.each { |entry| DocumentIndexEntry.create!(entry) }
      end
    end

    private

    attr_reader :document, :revision

    def entries
      [
        identity_entries,
        timeline_entries,
        party_member_entries
      ].flatten
    end

    def base_entry(index_type:, key:, value:, label:, metadata: {})
      {
        document: document,
        revision: revision,
        schema_document_id: document.schema_document_id,
        index_type: index_type,
        key: key,
        value: value,
        label: label,
        metadata: metadata
      }
    end

    def identity_entries
      [
        identity_entry("document_key", document.key, document_label),
        identity_entry("title", body["title"], document_label),
        identity_entry("name", body["name"], document_label)
      ].compact
    end

    def identity_entry(key, value, label)
      normalized = value.to_s.strip
      return nil if normalized.blank?

      base_entry(
        index_type: IDENTITY_TYPE,
        key: key,
        value: normalized,
        label: label.presence || normalized
      )
    end

    def timeline_entries
      return [] unless schema_key == "timeline-event"

      [
        base_entry(
          index_type: TIMELINE_EVENT_TYPE,
          key: "relative_time",
          value: body["relative_time"].to_s,
          label: document_label,
          metadata: {
            "relative_time" => body["relative_time"],
            "event_type" => body["event_type"]
          }
        ),
        participant_entry("party", body["party_key"], role: body["event_type"]),
        participant_entry("person", body["person_key"], role: body["event_type"]),
        participant_entries
      ].flatten.compact
    end

    def participant_entries
      Array(body["participants"]).filter_map do |participant|
        next unless participant.is_a?(Hash)

        participant_entry(participant["kind"], participant["key"], role: participant["role"], notes: participant["notes"])
      end
    end

    def participant_entry(kind, key, role: nil, notes: nil)
      normalized_kind = kind.to_s.strip
      normalized_key = key.to_s.strip
      return nil if normalized_kind.blank? || normalized_key.blank?

      base_entry(
        index_type: TIMELINE_PARTICIPANT_TYPE,
        key: normalized_kind,
        value: normalized_key,
        label: document_label,
        metadata: {
          "kind" => normalized_kind,
          "role" => role,
          "notes" => notes,
          "relative_time" => body["relative_time"],
          "event_type" => body["event_type"]
        }.compact
      )
    end

    def party_member_entries
      return [] unless schema_key == "party"

      Array(body["members"]).filter_map do |member|
        next unless member.is_a?(Hash)

        person_key = member["person_key"].to_s.strip
        next if person_key.blank?

        base_entry(
          index_type: PARTY_MEMBER_TYPE,
          key: "person",
          value: person_key,
          label: member["role"].presence || person_key,
          metadata: {
            "role" => member["role"],
            "notes" => member["notes"]
          }.compact
        )
      end
    end

    def body
      @body ||= revision.body
    end

    def document_label
      body["name"].presence || body["title"].presence || document.title.presence || document.key
    end

    def schema_key
      document.schema_document&.key
    end
  end
end
