# frozen_string_literal: true

require "rails_helper"

RSpec.describe DraftCommitPreflight do
  it "warns for unsupported schema declarations" do
    draft = build(
      :draft,
      body: {
        "$schema" => "https://json-schema.org/draft/1999-09/schema",
        "$id" => "http://example.test/schemas/old",
        "type" => "object"
      }
    )

    preflight = described_class.new(draft:)

    expect(preflight).to be_blocked
    expect(preflight.warnings.map(&:code)).to contain_exactly(
      DraftCommitPreflight::UNSUPPORTED_SCHEMA_DECLARATION
    )
  end

  it "does not warn when the unsupported schema warning is confirmed" do
    draft = build(:draft, body: { "$schema" => "https://example.test/schema" })

    preflight = described_class.new(
      draft:,
      confirmed_warning_codes: [ DraftCommitPreflight::UNSUPPORTED_SCHEMA_DECLARATION ]
    )

    expect(preflight).not_to be_blocked
  end

  it "does not warn for supported JSON Schema documents" do
    draft = build(
      :draft,
      body: {
        "$schema" => Document::JSON_SCHEMA_2020_12,
        "$id" => "http://example.test/schemas/current",
        "type" => "object"
      }
    )

    preflight = described_class.new(draft:)

    expect(preflight.warnings).to be_empty
    expect(preflight).not_to be_blocked
  end
end
