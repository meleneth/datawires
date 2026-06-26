# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentIndexes::ConfiguredDefinitions do
  it "emits root and array index entries from edit affordance definitions" do
    schema = create(:document, :with_schema_head_revision, key: "timeline-event")
    wrapper = create(:schema_wrapper, document: schema)
    edit_document = create(
      :document,
      :with_head_revision,
      domain: schema.domain,
      head_body: {
        "version" => 1,
        "rows" => [],
        "indexes" => [
          {
            "index_type" => "timeline_event",
            "key" => { "literal" => "relative_time" },
            "value" => { "root_ptr" => "/relative_time" },
            "label" => { "root_ptr" => "/title" },
            "metadata" => {
              "event_type" => { "root_ptr" => "/event_type" }
            }
          },
          {
            "index_type" => "timeline_participant",
            "source" => {
              "ptr" => "/participants",
              "each" => true
            },
            "key" => { "ptr" => "/kind" },
            "value" => { "ptr" => "/key" },
            "label" => { "root_ptr" => "/title" },
            "metadata" => {
              "role" => { "ptr" => "/role" },
              "relative_time" => { "root_ptr" => "/relative_time" }
            }
          }
        ]
      }
    )
    create(:edit_affordance, schema_wrapper: wrapper, edit_document: edit_document)
    document = create(
      :document,
      :with_head_revision,
      domain: schema.domain,
      schema_document: schema,
      head_body: {
        "relative_time" => 4,
        "event_type" => "general",
        "title" => "Arrival",
        "participants" => [
          { "kind" => "person", "key" => "ada", "role" => "witness" }
        ]
      }
    )

    entries = described_class.entries_for(document: document, revision: document.head_revision)

    expect(entries).to include(
      include(index_type: "timeline_event", key: "relative_time", value: "4", label: "Arrival", metadata: include("event_type" => "general")),
      include(index_type: "timeline_participant", key: "person", value: "ada", label: "Arrival", metadata: include("role" => "witness", "relative_time" => 4))
    )
  end

  it "supports conditions and metadata transforms" do
    schema = create(:document, :with_schema_head_revision, key: "timeline-event")
    wrapper = create(:schema_wrapper, document: schema)
    edit_document = create(
      :document,
      :with_head_revision,
      domain: schema.domain,
      head_body: {
        "version" => 1,
        "rows" => [],
        "indexes" => [
          {
            "index_type" => "party_membership",
            "key" => { "root_ptr" => "/party_key" },
            "value" => { "root_ptr" => "/person_key" },
            "label" => { "root_ptr" => "/title" },
            "condition" => {
              "value" => { "root_ptr" => "/event_type" },
              "in" => %w[party_join party_leave]
            },
            "metadata" => {
              "change" => {
                "root_ptr" => "/event_type",
                "transform" => {
                  "strip_prefix" => "party_"
                }
              }
            }
          }
        ]
      }
    )
    create(:edit_affordance, schema_wrapper: wrapper, edit_document: edit_document)
    document = create(
      :document,
      :with_head_revision,
      domain: schema.domain,
      schema_document: schema,
      head_body: {
        "relative_time" => 4,
        "event_type" => "party_leave",
        "title" => "Ada leaves",
        "party_key" => "expedition",
        "person_key" => "ada"
      }
    )

    expect(described_class.entries_for(document: document, revision: document.head_revision)).to include(
      include(index_type: "party_membership", key: "expedition", value: "ada", metadata: include("change" => "leave"))
    )
  end

  it "supports compound conditions for array-sourced entries" do
    schema = create(:document, :with_schema_head_revision, key: "timeline-event")
    wrapper = create(:schema_wrapper, document: schema)
    edit_document = create(
      :document,
      :with_head_revision,
      domain: schema.domain,
      head_body: {
        "version" => 1,
        "rows" => [],
        "indexes" => [
          {
            "index_type" => "party_membership",
            "source" => {
              "ptr" => "/participants",
              "each" => true
            },
            "key" => { "root_ptr" => "/party_key" },
            "value" => { "ptr" => "/key" },
            "label" => { "root_ptr" => "/title" },
            "condition" => {
              "all" => [
                {
                  "value" => { "root_ptr" => "/event_type" },
                  "equals" => "party_join"
                },
                {
                  "value" => { "ptr" => "/kind" },
                  "equals" => "person"
                }
              ]
            }
          }
        ]
      }
    )
    create(:edit_affordance, schema_wrapper: wrapper, edit_document: edit_document)
    document = create(
      :document,
      :with_head_revision,
      domain: schema.domain,
      schema_document: schema,
      head_body: {
        "relative_time" => 4,
        "event_type" => "party_join",
        "title" => "Company forms",
        "party_key" => "company",
        "participants" => [
          { "kind" => "party", "key" => "company" },
          { "kind" => "person", "key" => "ada" },
          { "kind" => "person", "key" => "bert" }
        ]
      }
    )

    expect(described_class.entries_for(document: document, revision: document.head_revision)).to include(
      include(index_type: "party_membership", key: "company", value: "ada"),
      include(index_type: "party_membership", key: "company", value: "bert")
    )
  end
end
