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
    attach_index_affordance(schema, Clusters::Catalog.timeline_event_schema)
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
    expect(DocumentIndexEntry.where(document: document, index_type: "party_membership").sole).to have_attributes(
      key: "expedition",
      value: "ada"
    )
  end

  it "derives person timeline participants from party membership at event time" do
    schema = create(:document, :with_schema_head_revision, key: "timeline-event")
    attach_index_affordance(schema, Clusters::Catalog.timeline_event_schema)
    domain = schema.domain
    join = create_timeline_event(
      domain: domain,
      schema: schema,
      key: "ada-joins",
      relative_time: 1,
      event_type: "party_join",
      title: "Ada joins",
      party_key: "expedition",
      person_key: "ada"
    )
    party_event = create_timeline_event(
      domain: domain,
      schema: schema,
      key: "expedition-arrives",
      relative_time: 2,
      event_type: "general",
      title: "Expedition arrives",
      participants: [
        { "kind" => "party", "key" => "expedition", "role" => "arrives" }
      ]
    )
    leave = create_timeline_event(
      domain: domain,
      schema: schema,
      key: "ada-leaves",
      relative_time: 3,
      event_type: "party_leave",
      title: "Ada leaves",
      party_key: "expedition",
      person_key: "ada"
    )
    later_party_event = create_timeline_event(
      domain: domain,
      schema: schema,
      key: "expedition-departs",
      relative_time: 4,
      event_type: "general",
      title: "Expedition departs",
      participants: [
        { "kind" => "party", "key" => "expedition", "role" => "departs" }
      ]
    )

    DocumentIndexes::RebuildTimelineDomain.call(domain: domain)

    expect(DocumentIndexEntry.where(document: join, index_type: "party_membership").pluck(:key, :value)).to include(
      [ "expedition", "ada" ]
    )
    expect(DocumentIndexEntry.where(document: leave, index_type: "party_membership").pluck(:metadata)).to include(
      include("change" => "leave")
    )
    expect(DocumentIndexEntry.where(document: party_event, index_type: "timeline_participant").pluck(:key, :value)).to include(
      [ "party", "expedition" ],
      [ "person", "ada" ]
    )
    expect(DocumentIndexEntry.where(document: later_party_event, index_type: "timeline_participant").pluck(:key, :value)).to include(
      [ "party", "expedition" ]
    )
    expect(DocumentIndexEntry.where(document: later_party_event, index_type: "timeline_participant").pluck(:key, :value)).not_to include(
      [ "person", "ada" ]
    )
  end

  it "indexes worldbuilding party members" do
    schema = create(:document, :with_schema_head_revision, key: "party")
    attach_index_affordance(schema, Clusters::Catalog.party_schema)
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

  def create_timeline_event(domain:, schema:, key:, relative_time:, event_type:, title:, party_key: "", person_key: "", participants: [])
    create(
      :document,
      :with_head_revision,
      domain: domain,
      schema_document: schema,
      key: key,
      title: title,
      head_body: {
        "relative_time" => relative_time,
        "event_type" => event_type,
        "title" => title,
        "party_key" => party_key,
        "person_key" => person_key,
        "participants" => participants
      }
    )
  end

  def attach_index_affordance(schema, schema_definition)
    wrapper = create(:schema_wrapper, document: schema)
    edit_document = create(
      :document,
      :with_head_revision,
      domain: schema.domain,
      head_body: schema_definition.fetch(:affordance)
    )
    create(:edit_affordance, schema_wrapper: wrapper, edit_document: edit_document)
  end
end
