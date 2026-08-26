# frozen_string_literal: true

require "rails_helper"

RSpec.describe Source, "execution leases" do
  it "acquires exclusively, expires, and only releases with the owning token" do
    source = create(:source)
    now = Time.current
    first = source.acquire_execution_lease(now:, ttl: 1.minute)

    expect(source.acquire_execution_lease(now: now + 30.seconds)).to be_nil
    expect(source.release_execution_lease("not-owner")).to be(false)

    second = source.acquire_execution_lease(now: now + 61.seconds)
    expect(second).not_to eq(first)
    expect(source.release_execution_lease(second)).to be(true)
    expect(source.reload).to have_attributes(lease_token: nil, leased_until: nil)
  end
end
