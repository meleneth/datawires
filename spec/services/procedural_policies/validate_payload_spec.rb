# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProceduralPolicies::ValidatePayload do
  it "validates payloads from their policy-declared types" do
    definition = ProceduralPolicies::Projection
      .build(ProceduralPolicies::Defaults.meeting_lifecycle)
      .command("establish_quorum")

    expect(described_class.call(payload: { "present" => true }, definition:)).to be_empty
    expect(described_class.call(payload: { "present" => "yes" }, definition:)).to eq(
      [ "Present must be a boolean." ]
    )
  end
end
