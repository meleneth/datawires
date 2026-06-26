# frozen_string_literal: true

module DocumentIndexes
  class RebuildJob < ApplicationJob
    queue_as :default

    def perform(document_id, revision_id)
      document = Document.find_by(id: document_id)
      revision = Revision.find_by(id: revision_id)
      return unless document && revision

      if document.schema_document&.key == "timeline-event"
        DocumentIndexes::RebuildTimelineDomain.call(domain: document.domain)
      else
        DocumentIndexes::Rebuild.call(document: document, revision: revision)
      end
    end
  end
end
