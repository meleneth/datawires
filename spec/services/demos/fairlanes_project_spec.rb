# frozen_string_literal: true

require "rails_helper"

RSpec.describe Demos::FairlanesProject do
  it "installs an idempotent public project showcase with cards and provenance" do
    actor = create(:user, name: "meleneth")

    expect { described_class.call(actor:) }.to change(Domain, :count).by(1)
      .and change(ProjectAffordance, :count).by(1)
      .and change(Observation, :count).by(28)
    domain = described_class.call(actor:)

    expect(domain).to be_public
    expect(domain.project_affordance.title).to eq("Fairlanes")
    expect(domain.documents.find_by!(key: "fairlanes-content-balance").body.fetch("bullets")).to include("71 monster declarations")
    expect(domain.project_affordance.default_board.projection.columns.flat_map(&:cards).map(&:kind)).to include(
      "document", "metric", "graph", "query", "image"
    )
    expect(domain.observations.count).to eq(28)
    expect(domain.observations.first.provenance).to include("configuration_revision_id" => domain.sources.sole.head_revision.id)
    expect(domain.sources.sole.source_runs.count).to eq(1)
  end
end
