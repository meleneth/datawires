# frozen_string_literal: true

require "rails_helper"

RSpec.describe Identity::Claims do
  it "normalizes and freezes collection claims" do
    claims = described_class.new(
      issuer: "issuer",
      subject: "subject",
      name: "Actor",
      groups: [ "members", "members", "admins" ],
      organization_hints: [ "body-2", "body-1" ]
    )

    expect(claims.groups).to eq(%w[admins members])
    expect(claims.organization_hints).to eq(%w[body-1 body-2])
    expect(claims).to be_frozen
    expect(claims.groups).to be_frozen
  end
end
