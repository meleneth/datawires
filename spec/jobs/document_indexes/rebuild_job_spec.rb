# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentIndexes::RebuildJob, type: :job do
  it "rebuilds ordinary documents directly" do
    document = create(:document, :with_head_revision)

    allow(DocumentIndexes::Rebuild).to receive(:call)
    allow(DocumentIndexes::RebuildTimelineDomain).to receive(:call)

    described_class.perform_now(document.id, document.head_revision.id)

    expect(DocumentIndexes::Rebuild).to have_received(:call).with(document: document, revision: document.head_revision)
    expect(DocumentIndexes::RebuildTimelineDomain).not_to have_received(:call)
  end

  it "refreshes all timeline indexes when a timeline event changes" do
    schema = create(:document, :with_schema_head_revision, key: "timeline-event")
    document = create(:document, :with_head_revision, domain: schema.domain, schema_document: schema)

    allow(DocumentIndexes::Rebuild).to receive(:call)
    allow(DocumentIndexes::RebuildTimelineDomain).to receive(:call)

    described_class.perform_now(document.id, document.head_revision.id)

    expect(DocumentIndexes::RebuildTimelineDomain).to have_received(:call).with(domain: document.domain)
    expect(DocumentIndexes::Rebuild).not_to have_received(:call)
  end
end
