# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProceduralPolicies::Defaults do
  it "loads the Meeting lifecycle as data from the versioned policy asset" do
    policy = described_class.meeting_lifecycle

    expect(policy.fetch("commands")).to include(
      "request_recognition",
      "recognize_member",
      "schedule_proposal"
    )
    expect(policy).to be_frozen
    expect(policy.fetch("commands")).to be_frozen
  end

  it "does not retain a Ruby-authored Meeting default policy" do
    expect(defined?(Meetings::DefaultPolicy)).to be_nil
  end
end
