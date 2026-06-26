# frozen_string_literal: true

require "rails_helper"

RSpec.describe Clusters::SeedDomain do
  it "seeds the worldbuilding schemas and default edit affordances" do
    domain = create(:domain)
    actor = create(:user)

    described_class.call(domain: domain, cluster_key: Clusters::Catalog::WORLD_BUILDING, actor: actor)

    expect(domain.documents.where(key: %w[person place thing party timeline-event]).count).to eq(5)

    timeline_schema = domain.documents.find_by!(key: "timeline-event")
    timeline_body = timeline_schema.body

    expect(timeline_schema.schema_wrapper).to be_present
    expect(timeline_body.dig("properties", "relative_time")).to include(
      "type" => "integer",
      "description" => "Relative timestamp. Negative values are allowed."
    )
    expect(timeline_body.dig("properties", "event_type", "enum")).to include("party_join", "party_leave")
    expect(timeline_body.dig("properties", "party_key")).to include("type" => "string")
    expect(timeline_body.dig("properties", "person_key")).to include("type" => "string")

    party_schema = domain.documents.find_by!(key: "party")
    expect(party_schema.body.dig("properties", "members", "items", "properties", "person_key")).to include(
      "type" => "string"
    )

    SchemaWrapper.where(document: domain.documents.where(key: %w[person place thing party timeline-event])).find_each do |wrapper|
      affordance = wrapper.edit_affordances.sole
      expect(affordance.title).to eq("Default")
      expect(affordance.body.fetch("screens").first.fetch("rows")).not_to be_empty
    end
  end

  it "does nothing for blank clusters" do
    domain = create(:domain)

    expect {
      described_class.call(domain: domain, cluster_key: "", actor: nil)
    }.not_to change(Document, :count)
  end
end
