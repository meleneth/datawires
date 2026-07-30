# frozen_string_literal: true

require "rails_helper"

RSpec.describe Authorization::BodyPolicy do
  it "grants capabilities from effective Datawires relationships" do
    body = create(:body)
    user = create(:user)
    actor = actor_context(user)
    create(:membership, body:, actor: user)
    create(:role_assignment, scope: body, actor: user, role: "secretary")

    expect(described_class.call(actor:, action: :submit_proposal, body:)).to be_allowed
    expect(described_class.call(actor:, action: :create_meeting, body:)).to be_allowed
    expect(described_class.call(actor:, action: :open_meeting, body:)).not_to be_allowed
  end

  it "uses the requested historical instant instead of current identity claims" do
    body = create(:body)
    user = create(:user)
    actor = actor_context(user, groups: [ "chairs" ])
    time = Time.zone.parse("2026-07-29 12:00:00")
    create(:role_assignment, scope: body, actor: user, role: "chair", effective_from: time - 1.day, effective_until: time)

    expect(described_class.call(actor:, action: :open_meeting, body:, at: time - 1.hour)).to be_allowed
    expect(described_class.call(actor:, action: :open_meeting, body:, at: time + 1.hour)).not_to be_allowed
  end

  def actor_context(user, groups: [])
    ActorContext.new(
      user:,
      claims: Identity::Claims.new(issuer: "spec", subject: user.id, name: "Actor", groups:)
    )
  end
end
