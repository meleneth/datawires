# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublishDraft do
  describe ".call" do
    it "publishes a draft into a revision and advances the document head" do
      doc = create(:document)
      draft = create(:draft, document: doc, body: { "title" => "Hello" })

      revision = described_class.call(draft:)

      expect(revision).to be_persisted
      expect(revision.document).to eq(doc)
      expect(revision.parent_revision).to be_nil
      expect(revision.body).to eq({ "title" => "Hello" })

      doc.reload
      expect(doc.head_revision).to eq(revision)

      draft.reload
      expect(draft.based_on_revision).to eq(revision)
      expect(draft.body).to eq(revision.body)
    end

    it "uses the current head as parent when draft is based on head" do
      doc = create(:document, :with_head_revision, head_body: { "v" => 1 })
      base = doc.head_revision

      draft = create(:draft, document: doc, based_on_revision: base, body: { "v" => 2 })

      revision = described_class.call(draft:, message: "bump")

      expect(revision.parent_revision).to eq(base)
      expect(revision.message).to eq("bump")

      doc.reload
      expect(doc.head_revision).to eq(revision)
    end

    it "raises StaleDraftError if draft is based on an older revision" do
      doc = create(:document, :with_head_revision, head_body: { "v" => 1 })
      rev1 = doc.head_revision
      rev2 = create(:revision, document: doc, parent_revision: rev1, body: { "v" => 2 })
      doc.update!(head_revision: rev2)

      stale_draft = create(:draft, document: doc, based_on_revision: rev1, body: { "v" => 999 })

      expect { described_class.call(draft: stale_draft) }
        .to raise_error(PublishDraft::StaleDraftError)

      doc.reload
      expect(doc.head_revision).to eq(rev2)
    end

    it "records created_by when actor is provided" do
      actor = create(:user)
      doc = create(:document)
      draft = create(:draft, document: doc, body: { "x" => 1 })

      revision = described_class.call(draft:, actor:)

      expect(revision.created_by).to eq(actor)
    end
  end
end
