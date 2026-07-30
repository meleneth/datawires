# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateProceduralPolicy do
  it "creates a schema-backed, projected policy document" do
    body = create(:body)
    policy = described_class.call(
      body:,
      name: ProceduralPolicies::Defaults.meeting_lifecycle.fetch("name"),
      definition: ProceduralPolicies::Defaults.meeting_lifecycle,
      actor: create(:user)
    )

    expect(policy.policy_document.schema_document.key).to eq(ProceduralPolicies::Schema::KEY)
    expect(policy.projection.command("open_meeting")).to have_attributes(
      capability: :open_meeting,
      event_type: "MeetingOpened",
      event_version: 1
    )
  end

  it "immutably upgrades an existing compatible policy schema before revising policy data" do
    body = create(:body)
    actor = create(:user)
    policy = described_class.call(
      body:,
      name: ProceduralPolicies::Defaults.meeting_lifecycle.fetch("name"),
      definition: ProceduralPolicies::Defaults.meeting_lifecycle,
      actor:
    )
    schema = policy.policy_document.schema_document
    old_schema = ProceduralPolicies::Schema::BODY.deep_dup
    old_schema["required"] = %w[version name commands]
    old_schema["properties"].delete("role_capabilities")
    old_revision = schema.revisions.create!(
      parent_revision: schema.head_revision,
      body: old_schema,
      message: "Install old schema fixture",
      created_by: actor
    )
    schema.update!(head_revision: old_revision)
    policy_definition = ProceduralPolicies::Defaults.meeting_lifecycle.deep_dup
    policy_definition["name"] = "Revised lifecycle"

    described_class.call(
      body:,
      name: policy.name,
      definition: policy_definition,
      actor:
    )

    expect(schema.reload.body).to eq(ProceduralPolicies::Schema::BODY)
    expect(schema.head_revision.parent_revision).to eq(old_revision)
    expect(policy.policy_document.reload.body).to eq(policy_definition)
  end
end
