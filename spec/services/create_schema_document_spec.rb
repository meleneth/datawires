# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateSchemaDocument do
  it "creates a document and a draft with minimal schema body" do
    domain = create(:domain)
    actor = create(:user)

    result = described_class.call(domain:, key: "foo", title: "Foo", actor:)

    expect(result.document).to be_persisted
    expect(result.document.domain).to eq(domain)
    expect(result.document.key).to eq("foo")
    expect(result.document.title).to eq("Foo")

    expect(result.draft).to be_persisted
    expect(result.draft.document).to eq(result.document)
    expect(result.draft.created_by).to eq(actor)

    expect(result.draft.body).to include(
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "type" => "object",
      "properties" => {},
    )
  end
end
