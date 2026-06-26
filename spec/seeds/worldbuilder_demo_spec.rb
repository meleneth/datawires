# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/worldbuilder_demo")

RSpec.describe Seeds::WorldbuilderDemo do
  it "seeds a deterministic worldbuilding demo domain" do
    described_class.seed!

    domain = Domain.find(described_class::DOMAIN_ID)
    expect(domain.name).to eq("Worldbuilder Demo")
    expect(domain.documents.where(key: %w[person place thing party timeline-event]).count).to eq(5)

    frodo = domain.documents.find_by!(key: "frodo")
    fellowship = domain.documents.find_by!(key: "fellowship")
    formation = domain.documents.find_by!(key: "fellowship-forms")

    expect(frodo.id).to eq(described_class::DOCUMENT_IDS.fetch("frodo"))
    expect(fellowship.id).to eq(described_class::DOCUMENT_IDS.fetch("fellowship"))
    expect(formation.id).to eq(described_class::DOCUMENT_IDS.fetch("fellowship-forms"))
    expect(frodo.schema_document.key).to eq("person")
    expect(fellowship.schema_document.key).to eq("party")
    expect(formation.schema_document.key).to eq("timeline-event")
    expect(formation.body).to include(
      "event_type" => "party_join",
      "party_key" => "fellowship",
      "person_key" => "frodo"
    )
    expect(formation.body.fetch("participants").pluck("kind")).to include("party", "person")

    expect(DocumentIndexEntry.where(document: formation, index_type: "timeline_participant").pluck(:key, :value)).to include(
      [ "party", "fellowship" ],
      [ "person", "frodo" ],
      [ "person", "sam" ]
    )
    expect(DocumentIndexEntry.where(document: formation, index_type: "party_membership").pluck(:key, :value)).to include(
      [ "fellowship", "frodo" ],
      [ "fellowship", "aragorn" ],
      [ "fellowship", "sam" ]
    )

    timeline_schema = domain.documents.find_by!(key: "timeline-event")
    expect(timeline_schema.schema_wrapper.view_affordances.sole.title).to eq("Timeline")

    aragorn = domain.documents.find_by!(key: "aragorn")
    person_view = domain.documents.find_by!(key: "person").schema_wrapper.view_affordances.sole
    aragorn_events = ViewAffordances::Projection.build(document: aragorn, view_affordance: person_view).data.fetch("events").map { |event| event.fetch("title") }
    expect(aragorn_events).to include(
      "Fellowship leaves Rivendell",
      "Gandalf parts from the company in Moria",
      "Boromir parts from the company"
    )
  end

  it "is idempotent" do
    described_class.seed!

    expect {
      described_class.seed!
    }.not_to change { [ Domain.count, Document.count, Revision.count ] }
  end
end
