# frozen_string_literal: true

require "set"

module DocumentIndexes
  class Rebuild
    IDENTITY_TYPE = "identity"
    PARTY_MEMBER_TYPE = "party_member"
    PARTY_MEMBERSHIP_TYPE = "party_membership"
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
        configured_index_entries,
        timeline_entries
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
        derived_party_participant_entries
      ].flatten.compact
    end

    def configured_index_entries
      DocumentIndexes::ConfiguredDefinitions.entries_for(document: document, revision: revision)
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

    def derived_party_participant_entries
      relative_time = integer_or_nil(body["relative_time"])
      return [] if relative_time.nil?

      explicit_people = Set.new(
        [
          body["person_key"].to_s.strip.presence,
          *Array(body["participants"]).filter_map do |participant|
            next unless participant.is_a?(Hash)
            next unless participant["kind"].to_s == "person"

            participant["key"].to_s.strip.presence
          end
        ].compact
      )
      party_keys.flat_map do |party_key|
        active_members_for(party_key, relative_time).filter_map do |person_key|
          next if explicit_people.include?(person_key)

          explicit_people << person_key
          participant_entry(
            "person",
            person_key,
            role: "present with #{party_key}",
            notes: "Derived from party membership."
          )
        end
      end
    end

    def party_keys
      [
        body["party_key"].to_s.strip.presence,
        *Array(body["participants"]).filter_map do |participant|
          next unless participant.is_a?(Hash)
          next unless participant["kind"].to_s == "party"

          participant["key"].to_s.strip.presence
        end
      ].compact.uniq
    end

    def active_members_for(party_key, relative_time)
      party_membership_changes_for(party_key).each_with_object(Set.new) do |change, members|
        next if change.fetch(:relative_time) > relative_time

        if change.fetch(:event_type) == "party_join"
          members << change.fetch(:person_key)
        elsif change.fetch(:event_type) == "party_leave"
          members.delete(change.fetch(:person_key))
        end
      end.to_a
    end

    def party_membership_changes_for(party_key)
      timeline_documents.flat_map do |timeline_document|
        event_body = timeline_document.body
        event_type = event_body["event_type"].to_s
        next unless %w[party_join party_leave].include?(event_type)
        next unless event_body["party_key"].to_s.strip == party_key

        member_relative_time = integer_or_nil(event_body["relative_time"])
        next [] if member_relative_time.nil?

        person_keys_for_membership_event(event_body).map do |person_key|
          {
            relative_time: member_relative_time,
            event_type: event_type,
            person_key: person_key
          }
        end
      end.compact.sort_by do |change|
        [ change.fetch(:relative_time), membership_change_order(change.fetch(:event_type)), change.fetch(:person_key) ]
      end
    end

    def person_keys_for_membership_event(event_body)
      [
        event_body["person_key"].to_s.strip.presence,
        *Array(event_body["participants"]).filter_map do |participant|
          next unless participant.is_a?(Hash)
          next unless participant["kind"].to_s == "person"

          participant["key"].to_s.strip.presence
        end
      ].compact.uniq
    end

    def timeline_documents
      return Document.none unless timeline_schema

      document.domain.documents
        .includes(:head_revision)
        .with_head
        .where(schema_document: timeline_schema)
    end

    def timeline_schema
      @timeline_schema ||= document.domain.documents.find_by(key: "timeline-event")
    end

    def membership_change_order(event_type)
      event_type == "party_join" ? 0 : 1
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

    def integer_or_nil(value)
      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
