# frozen_string_literal: true

require "rails_helper"

RSpec.describe Document, type: :model do
  it "allows plain documents without a key" do
    doc = build(:document, key: nil)
    expect(doc).to be_valid
  end

  it "requires a key for committed supported schema documents" do
    doc = create(:document, key: nil)
    revision = create(
      :revision,
      document: doc,
      body: {
        "$schema" => Document::JSON_SCHEMA_2020_12,
        "$id" => "http://example.test/schemas/nameless",
        "type" => "object",
        "properties" => {}
      }
    )

    doc.head_revision = revision

    expect(doc).not_to be_valid
    expect(doc.errors[:key]).to include("is required for schema documents")
  end

  it "uniqueness of key scoped to domain" do
    domain = create(:domain)
    create(:document, domain: domain, key: "alpha")

    dup = build(:document, domain: domain, key: "alpha")
    expect(dup).not_to be_valid
  end

  it "does not allow schema_document to point at an unsupported schema declaration" do
    unsupported_schema = create(
      :document,
      :with_head_revision,
      head_body: {
        "$schema" => "https://json-schema.org/draft/1999-09/schema",
        "$id" => "http://example.test/schemas/old",
        "type" => "object"
      }
    )

    document = build(:document, schema_document: unsupported_schema)

    expect(document).not_to be_valid
    expect(document.errors[:schema_document]).to include("must reference a supported schema document")
  end

  it "allows schema_document to point at a supported schema document" do
    schema = create(:document, :with_schema_head_revision)
    document = build(:document, schema_document: schema)

    expect(document).to be_valid
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
