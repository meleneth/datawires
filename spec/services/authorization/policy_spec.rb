# frozen_string_literal: true

require "rails_helper"

RSpec.describe Authorization::Policy do
  it "returns an explicit allow decision through the user compatibility seam" do
    user = create(:user)
    actor = ActorContext.new(
      user:,
      claims: Identity::Claims.new(issuer: "spec", subject: user.id, name: "Actor")
    )

    decision = described_class.call(actor:, action: :create_document, resource: {})

    expect(decision).to be_allowed
    expect(decision.reason).to be_nil
  end

  it "fails closed without an actor" do
    decision = described_class.call(actor: nil, action: :create_document, resource: {})

    expect(decision).not_to be_allowed
    expect(decision.reason).to eq("An authenticated actor is required.")
  end
end
