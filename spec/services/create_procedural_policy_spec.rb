# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateProceduralPolicy do
  it "creates a schema-backed, projected policy document" do
    body = create(:body)
    policy = described_class.call(
      body:,
      name: Meetings::DefaultPolicy::NAME,
      definition: Meetings::DefaultPolicy::BODY,
      actor: create(:user)
    )

    expect(policy.policy_document.schema_document.key).to eq(ProceduralPolicies::Schema::KEY)
    expect(policy.projection.command("open_meeting")).to have_attributes(
      capability: :open_meeting,
      event_type: "MeetingOpened",
      event_version: 1
    )
  end
end
