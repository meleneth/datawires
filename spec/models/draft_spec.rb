# frozen_string_literal: true

require "rails_helper"

RSpec.describe Draft, type: :model do
  it "requires body" do
    draft = build(:draft, body: nil)
    expect(draft).not_to be_valid
  end

  it "requires based_on_revision to belong to the same document" do
    doc1 = create(:document)
    doc2 = create(:document)
    base = create(:revision, document: doc1)

    draft = build(:draft, document: doc2, based_on_revision: base)
    expect(draft).not_to be_valid
    expect(draft.errors[:based_on_revision]).to be_present
  end

  describe "#editor_dom_id_for" do
    it "builds a stable inner editor dom id for the root path" do
      draft = build(:draft)

      expect(draft.editor_dom_id_for("/")).to eq("editor_root")
    end

    it "builds a stable inner editor dom id for a nested path" do
      draft = build(:draft)

      expect(draft.editor_dom_id_for("/items/0/title")).to eq("editor_items_0_title")
    end
  end
end
