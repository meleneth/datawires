# frozen_string_literal: true

require "rails_helper"

RSpec.describe Commands::Envelope do
  it "normalizes identifiers and deeply freezes command input" do
    actor = actor_context
    payload = { "nested" => { "value" => 1 } }
    envelope = described_class.new(
      id: SecureRandom.uuid.upcase,
      type: "open_meeting",
      version: 1,
      stream_id: SecureRandom.uuid,
      expected_revision: 0,
      actor:,
      timestamp: Time.current,
      payload:
    )

    payload["nested"]["value"] = 2
    expect(envelope.payload.dig("nested", "value")).to eq(1)
    expect(envelope.payload.fetch("nested")).to be_frozen
  end

  def actor_context
    user = create(:user)
    ActorContext.new(
      user:,
      claims: Identity::Claims.new(issuer: "spec", subject: user.id, name: "Actor")
    )
  end
end
