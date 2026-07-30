# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProceduralPolicies::LegacyEventEffects do
  it "loads deeply frozen, versioned mappings from data" do
    mappings = described_class.mappings

    expect(mappings.dig("MeetingOpened", "1", "effects")).to be_an(Array)
    expect(mappings).to be_frozen
    expect(mappings.fetch("MeetingOpened")).to be_frozen
  end

  it "fails closed for unregistered compatibility mechanics" do
    document = {
      "version" => 1,
      "events" => {
        "Example" => {
          "1" => {
            "effects" => [
              { "op" => "execute_ruby", "field" => "status" }
            ]
          }
        }
      }
    }

    expect {
      described_class.validate!(document)
    }.to raise_error(ArgumentError, "legacy event effect operation is not registered")
  end
end
