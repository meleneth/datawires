# frozen_string_literal: true

require "rails_helper"

RSpec.describe SourceCredential do
  it "encrypts secret material at rest" do
    credential = described_class.create!(domain: create(:domain), name: "weather", secret: { "headers" => { "X-Api-Key" => "secret" } })

    expect(credential.encrypted_payload).not_to include("secret")
    expect(credential.reload.secret).to eq("headers" => { "X-Api-Key" => "secret" })
  end
end
