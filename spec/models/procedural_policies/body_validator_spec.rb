# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProceduralPolicies::BodyValidator do
  it "accepts the constrained default Meeting policy" do
    expect(described_class.new(ProceduralPolicies::Defaults.meeting_lifecycle)).to be_valid
  end

  it "rejects unregistered capabilities, event effects, and payload types" do
    body = ProceduralPolicies::Defaults.meeting_lifecycle.deep_dup
    definition = body["commands"]["open_meeting"]
    definition["capability"] = "keycloak_admin"
    definition["command_version"] = 0
    definition["event_type"] = "ExecuteRuby"
    definition["payload"] = { "code" => "ruby" }

    validator = described_class.new(body)

    expect(validator).not_to be_valid
    expect(validator.errors).to include("commands.open_meeting.capability must be registered")
    expect(validator.errors).to include("commands.open_meeting.command_version must be positive")
    expect(validator.errors).to include("commands.open_meeting.payload.code must use a registered type")
  end

  it "rejects malformed registered stack operations before runtime" do
    body = ProceduralPolicies::Defaults.meeting_lifecycle.deep_dup
    body["commands"]["open_meeting"]["conditions"] = [
      { "op" => "stack_top_equals", "value" => 1 }
    ]
    body["commands"]["open_meeting"]["effects"] = [
      { "op" => "stack_push", "field" => "pending_question_stack" }
    ]

    validator = described_class.new(body)

    expect(validator).not_to be_valid
    expect(validator.errors).to include("commands.open_meeting.conditions[0].field is required")
    expect(validator.errors).to include("commands.open_meeting.effects[0].value is required")
  end

  it "rejects malformed role-capability policy data" do
    body = ProceduralPolicies::Defaults.meeting_lifecycle.deep_dup
    body["role_capabilities"]["open_meeting"] = [ "chair", "chair" ]

    validator = described_class.new(body)

    expect(validator).not_to be_valid
    expect(validator.errors).to include(
      "role_capabilities.open_meeting must contain unique non-empty roles"
    )
  end

  it "rejects undeclared resource methods in conditions and bindings" do
    body = ProceduralPolicies::Defaults.meeting_lifecycle.deep_dup
    command = body["commands"]["schedule_proposal"]
    command["conditions"][0]["attribute"] = "destroy!"
    command["event_payload"]["proposal_id"]["attribute"] = "delete"

    validator = described_class.new(body)

    expect(validator).not_to be_valid
    expect(validator.errors).to include(
      "commands.schedule_proposal.conditions[0].attribute must be registered",
      "commands.schedule_proposal.event_payload.proposal_id.attribute must be registered"
    )
  end

  it "rejects a derived identity binding without a stable name" do
    body = ProceduralPolicies::Defaults.meeting_lifecycle.deep_dup
    body["commands"]["open_meeting"]["event_payload"] = {
      "id" => { "source" => "derived_id", "name" => "" }
    }

    validator = described_class.new(body)

    expect(validator).not_to be_valid
    expect(validator.errors).to include(
      "commands.open_meeting.event_payload.id.name must be non-empty"
    )
  end
end
