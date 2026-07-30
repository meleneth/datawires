# frozen_string_literal: true

require "rails_helper"

RSpec.describe StructuredDocuments::ApplyOperation do
  it "replaces a structured value without mutating the base content" do
    content = { "article" => { "amount" => 10, "label" => "dues" } }
    operation = {
      "version" => 1,
      "type" => "replace",
      "base_version" => 1,
      "path" => "/article/amount",
      "value" => 15
    }

    result = described_class.call(content:, operation:, current_version: 1)

    expect(content.dig("article", "amount")).to eq(10)
    expect(result.content.dig("article", "amount")).to eq(15)
    expect(result.content).to be_frozen
    expect(result.operation).to eq(operation)
    expect(result.operation).to be_frozen
  end

  it "rejects stale bases, missing targets, and unsupported operations" do
    content = { "article" => { "amount" => 10 } }
    base = {
      "version" => 1,
      "type" => "replace",
      "base_version" => 1,
      "path" => "/article/amount",
      "value" => 15
    }

    expect {
      described_class.call(content:, operation: base.merge("base_version" => 2), current_version: 1)
    }.to raise_error(described_class::Invalid, /stale/)
    expect {
      described_class.call(content:, operation: base.merge("path" => "/missing"), current_version: 1)
    }.to raise_error(described_class::Invalid, /does not exist/)
    expect {
      described_class.call(content:, operation: base.merge("type" => "execute"), current_version: 1)
    }.to raise_error(described_class::Invalid, /not supported/)
  end
end
