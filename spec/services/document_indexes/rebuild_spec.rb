# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentIndexes::Rebuild do
  it "indexes schema-backed document identity values" do
    schema = create(:document, :with_name_schema, key: "person")
    create(:schema_wrapper, document: schema)
    document = create(
      :document,
      :with_head_revision,
      domain: schema.domain,
      key: "ada",
      title: "Ada document",
      schema_document: schema,
      head_body: {
        "name" => "Ada Lovelace",
        "title" => "Countess"
      }
    )

    described_class.call(document: document)

    entries = DocumentIndexEntry.where(document: document, index_type: "identity")

    expect(entries.pluck(:key, :value, :label)).to include(
      [ "document_key", "ada", "Ada Lovelace" ],
      [ "title", "Countess", "Ada Lovelace" ],
      [ "name", "Ada Lovelace", "Ada Lovelace" ]
    )
    expect(entries.first.schema_document).to eq(schema)
    expect(entries.first.revision).to eq(document.head_revision)
  end

  it "replaces stale rows when rebuilding" do
    schema = create(:document, :with_name_schema, key: "person")
    document = create(
      :document,
      :with_head_revision,
      domain: schema.domain,
      schema_document: schema,
      head_body: { "name" => "Old" }
    )

    described_class.call(document: document)

    new_revision = create(:revision, document: document, parent_revision: document.head_revision, body: { "name" => "New" })
    document.update!(head_revision: new_revision)

    described_class.call(document: document, revision: new_revision)

    expect(DocumentIndexEntry.where(document: document).pluck(:value)).to include("New")
    expect(DocumentIndexEntry.where(document: document).pluck(:value)).not_to include("Old")
  end

  it "skips stale revisions" do
    schema = create(:document, :with_name_schema, key: "person")
    document = create(
      :document,
      :with_head_revision,
      domain: schema.domain,
      schema_document: schema,
      head_body: { "name" => "Old" }
    )
    stale_revision = document.head_revision
    new_revision = create(:revision, document: document, parent_revision: stale_revision, body: { "name" => "New" })
    document.update!(head_revision: new_revision)

    described_class.call(document: document, revision: stale_revision)

    expect(DocumentIndexEntry.where(document: document)).to be_empty
  end

  it "indexes worldbuilding timeline participants and party join fields" do
    schema = create(:document, :with_schema_head_revision, key: "timeline-event")
    document = create(
      :document,
      :with_head_revision,
      domain: schema.domain,
      schema_document: schema,
      head_body: {
        "relative_time" => -4,
        "title" => "Ada joins the expedition",
        "event_type" => "party_join",
        "party_key" => "expedition",
        "person_key" => "ada",
        "participants" => [
          { "kind" => "place", "key" => "london", "role" => "origin" }
        ]
      }
    )

    described_class.call(document: document)

    expect(DocumentIndexEntry.where(document: document, index_type: "timeline_event").sole).to have_attributes(
      key: "relative_time",
      value: "-4",
      label: "Ada joins the expedition"
    )
    expect(DocumentIndexEntry.where(document: document, index_type: "timeline_participant").pluck(:key, :value)).to include(
      [ "party", "expedition" ],
      [ "person", "ada" ],
      [ "place", "london" ]
    )
  end

  it "indexes worldbuilding party members" do
    schema = create(:document, :with_schema_head_revision, key: "party")
    document = create(
      :document,
      :with_head_revision,
      domain: schema.domain,
      schema_document: schema,
      head_body: {
        "name" => "Expedition",
        "members" => [
          { "person_key" => "ada", "role" => "Navigator" }
        ]
      }
    )

    described_class.call(document: document)

    expect(DocumentIndexEntry.where(document: document, index_type: "party_member").sole).to have_attributes(
      key: "person",
      value: "ada",
      label: "Navigator"
    )
  end
end
