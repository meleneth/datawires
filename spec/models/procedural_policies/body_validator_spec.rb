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
end
