# frozen_string_literal: true

require "rails_helper"

RSpec.describe Identity::ResolveActor do
  it "maps an issuer and subject stably while refreshing profile claims" do
    first = described_class.call(
      claims: Identity::Claims.new(issuer: "https://issuer", subject: "abc", name: "Ada")
    )
    second = described_class.call(
      claims: Identity::Claims.new(issuer: "https://issuer", subject: "abc", name: "Ada Updated")
    )

    expect(second.user).to eq(first.user)
    expect(second.user.name).to eq("Ada Updated")
    expect(second.user.identity_issuer).to eq("https://issuer")
    expect(second.user.identity_subject).to eq("abc")
  end

  it "adopts a legacy external id without changing the user identity" do
    user = create(:user, external_id: "legacy")

    actor = described_class.call(
      claims: Identity::Claims.new(issuer: "https://issuer", subject: "legacy", name: "Legacy")
    )

    expect(actor.user).to eq(user)
    expect(user.reload.identity_subject).to eq("legacy")
  end

  it "keeps equal subject strings from different issuers as different actors" do
    first = described_class.call(
      claims: Identity::Claims.new(issuer: "https://one", subject: "shared", name: "One")
    )
    second = described_class.call(
      claims: Identity::Claims.new(issuer: "https://two", subject: "shared", name: "Two")
    )

    expect(second.user).not_to eq(first.user)
    expect(second.user.identity_subject).to eq("shared")
    expect(second.user.external_id).to be_nil
  end
end
