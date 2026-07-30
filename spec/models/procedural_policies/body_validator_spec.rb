# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProceduralPolicies::BodyValidator do
  it "accepts the constrained default Meeting policy" do
    expect(described_class.new(Meetings::DefaultPolicy::BODY)).to be_valid
  end

  it "rejects unregistered capabilities, event effects, and payload types" do
    body = Meetings::DefaultPolicy::BODY.deep_dup
    definition = body["commands"]["open_meeting"]
    definition["capability"] = "keycloak_admin"
    definition["event_type"] = "ExecuteRuby"
    definition["payload"] = { "code" => "ruby" }

    validator = described_class.new(body)

    expect(validator).not_to be_valid
    expect(validator.errors).to include("commands.open_meeting.capability must be registered")
    expect(validator.errors).to include("commands.open_meeting.event_type must be registered")
    expect(validator.errors).to include("commands.open_meeting.payload.code must use a registered type")
  end
end
