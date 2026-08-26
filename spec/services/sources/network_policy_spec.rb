# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sources::NetworkPolicy do
  it "rejects loopback and private source destinations" do
    allow(Resolv).to receive(:getaddresses).with("internal.test").and_return([ "127.0.0.1", "10.0.0.2" ])

    expect {
      described_class.validate!(URI("https://internal.test/data"))
    }.to raise_error(Sources::NetworkPolicy::UnsafeAddress, /private or reserved/)
  end

  it "accepts public destinations and explicit operator allowlists" do
    allow(Resolv).to receive(:getaddresses).with("public.test").and_return([ "8.8.8.8" ])
    expect(described_class.validate!(URI("https://public.test/data"))).to be(true)

    allow(described_class).to receive(:allowed_hosts).and_return([ "internal.test" ])
    expect(described_class.validate!(URI("https://internal.test/data"))).to be(true)
  end
end
