# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProceduralPolicies::Resources do
  it "projects only registered immutable Proposal lineage attributes" do
    proposal = create(:proposal)

    resource = described_class.resolve(type: "proposal", id: proposal.id)

    expect(resource.keys).to contain_exactly(
      "id",
      "body_id",
      "submitted_revision_id",
      "submitted_content",
      "title"
    )
    expect(resource).to be_frozen
    expect(resource.fetch("submitted_content")).to be_frozen
  end

  it "fails closed for unknown resource types" do
    expect {
      described_class.resolve(type: "ruby_constant", id: SecureRandom.uuid)
    }.to raise_error(described_class::UnknownType, "Policy resource type is not registered.")
  end
end
