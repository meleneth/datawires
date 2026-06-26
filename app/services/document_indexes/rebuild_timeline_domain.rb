# frozen_string_literal: true

module DocumentIndexes
  class RebuildTimelineDomain
    def self.call(domain:)
      new(domain:).call
    end

    def initialize(domain:)
      raise ArgumentError, "domain must be a Domain" unless domain.is_a?(Domain)

      @domain = domain
    end

    def call
      return unless timeline_schema

      timeline_documents.find_each do |document|
        DocumentIndexes::Rebuild.call(document: document)
      end
    end

    private

    attr_reader :domain

    def timeline_documents
      domain.documents
        .includes(:head_revision)
        .with_head
        .where(schema_document: timeline_schema)
    end

    def timeline_schema
      @timeline_schema ||= domain.documents.find_by(key: "timeline-event")
    end
  end
end
