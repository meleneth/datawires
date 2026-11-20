# frozen_string_literal: true

require "rails_helper"

RSpec.describe Documents::CreateFromSchema do
  let(:domain) { create(:domain) }
  let(:schema) { create(:document, :with_schema_head_revision, domain:, key: "task") }
  let(:wrapper) { create(:schema_wrapper, document: schema) }
  let(:actor) { create(:user) }

  it "writes the initial parent reference to both immutable revision and mutable draft" do
    document, draft = described_class.call(schema_wrapper: wrapper, actor:,
      initial_values: { "project_key" => "project-one" })

    expect(document.schema_document).to eq(schema)
    expect(document.body).to eq("project_key" => "project-one")
    expect(draft.body).to eq("project_key" => "project-one")
    expect(draft.based_on_revision).to eq(document.head_revision)
  end

  it "retains the original empty-body behavior when no initial values are supplied" do
    document, draft = described_class.call(schema_wrapper: wrapper, actor:)
    expect(document.body).to eq({})
    expect(draft.body).to eq({})
  end

  it "rejects non-object initial values before creating a document" do
    before_count = Document.count
    expect {
      described_class.call(schema_wrapper: wrapper, actor:, initial_values: [ "invalid" ])
    }.to raise_error(ArgumentError, "initial_values must be an object")
    expect(Document.count).to eq(before_count)
  end

  it "does not retain mutable references to the caller's initial values" do
    values = { "metadata" => { "items" => [ "original" ] } }
    document, = described_class.call(schema_wrapper: wrapper, actor:, initial_values: values)
    values["metadata"]["items"] << "changed"

    expect(document.body.fetch("metadata").fetch("items")).to eq([ "original" ])
  end
end
