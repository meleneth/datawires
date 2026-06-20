# frozen_string_literal: true

require "rails_helper"

RSpec.describe Document, type: :model do
  it "requires key" do
    doc = build(:document, key: nil)
    expect(doc).not_to be_valid
  end

  it "uniqueness of key scoped to domain" do
    domain = create(:domain)
    create(:document, domain: domain, key: "alpha")

    dup = build(:document, domain: domain, key: "alpha")
    expect(dup).not_to be_valid
  end

  it "#body returns {} without a head revision" do
    doc = create(:document)
    expect(doc.body).to eq({})
  end

  it "#body returns head revision body when present" do
    doc = create(:document, :with_head_revision, head_body: { "x" => 1 })
    expect(doc.body).to eq({ "x" => 1 })
  end

  describe "#draft_for" do
    it "requires an actor" do
      doc = create(:document)

      expect { doc.draft_for(actor: nil) }.to raise_error(ArgumentError, "actor is required")
    end
  end
end
