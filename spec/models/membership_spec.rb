# frozen_string_literal: true

require "rails_helper"

RSpec.describe Membership, type: :model do
  it "queries the active relationship at a historical instant" do
    time = Time.zone.parse("2026-07-29 12:00:00")
    active = create(:membership, effective_from: time - 1.day, effective_until: time + 1.day)
    create(:membership, body: active.body, effective_from: time + 1.hour)
    create(:membership, body: active.body, effective_from: time - 2.days, effective_until: time)

    expect(active.body.memberships_at(time)).to contain_exactly(active)
  end

  it "rejects a non-positive effective range" do
    membership = build(:membership, effective_from: Time.current, effective_until: 1.hour.ago)

    expect(membership).not_to be_valid
  end
end
