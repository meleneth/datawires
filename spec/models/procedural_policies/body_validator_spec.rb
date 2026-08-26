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

  it "rejects an unscoped stack-top binding" do
    body = ProceduralPolicies::Defaults.meeting_lifecycle.deep_dup
    body["commands"]["open_meeting"]["event_payload"] = {
      "id" => { "source" => "stack_top", "field" => "unknown", "attribute" => "" }
    }

    validator = described_class.new(body)

    expect(validator).not_to be_valid
    expect(validator.errors).to include(
      "commands.open_meeting.event_payload.id.field must be a registered projection field",
      "commands.open_meeting.event_payload.id.attribute must be non-empty"
    )
  end

  it "rejects an incomplete structured-document operation binding" do
    body = ProceduralPolicies::Defaults.meeting_lifecycle.deep_dup
    body["commands"]["open_meeting"]["event_payload"] = {
      "content" => {
        "source" => "document_operation",
        "document" => { "source" => "literal", "value" => {} }
      }
    }

    validator = described_class.new(body)

    expect(validator).not_to be_valid
    expect(validator.errors).to include(
      "commands.open_meeting.event_payload.content.operation is required",
      "commands.open_meeting.event_payload.content.current_version is required"
    )
  end

  it "reports malformed policy and command containers without cascading" do
    expect(described_class.new(nil).errors).to eq([ "body must be an object" ])

    validator = described_class.new({ "version" => 2, "name" => "", "role_capabilities" => [], "commands" => [] })
    expect(validator.errors).to contain_exactly(
      "version must be 1", "name must be a non-empty string", "role_capabilities must be an object",
      "commands must be an object"
    )

    validator = described_class.new({ "version" => 1, "name" => "Policy", "role_capabilities" => {},
      "commands" => { "" => nil } })
    expect(validator.errors).to contain_exactly("commands. name must be non-empty", "commands. must be an object")
  end

  it "reports malformed optional command collections in one branch matrix" do
    body = ProceduralPolicies::Defaults.meeting_lifecycle.deep_dup
    command = body["commands"]["open_meeting"]
    command.merge!(
      "command_version" => "one", "allowed_statuses" => [ "missing" ], "event_type" => "",
      "event_version" => 0, "payload" => [], "resources" => [], "conditions" => {}, "effects" => {},
      "event_payload" => { "bad" => { "source" => "unknown" } }, "document_outputs" => {}
    )

    expect(described_class.new(body).errors).to include(
      "commands.open_meeting.command_version must be positive",
      "commands.open_meeting.allowed_statuses must contain known statuses",
      "commands.open_meeting.event_type must be a non-empty string",
      "commands.open_meeting.event_version must be positive",
      "commands.open_meeting.payload must be an object",
      "commands.open_meeting.resources must be an object",
      "commands.open_meeting.conditions must be an array",
      "commands.open_meeting.effects must be an array",
      "commands.open_meeting.event_payload.bad.source must be registered",
      "commands.open_meeting.document_outputs must be an array"
    )
  end
end
