# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncSchemaWrapperForDocument do
  it "creates a wrapper for a supported schema document" do
    document = create(:document, :with_schema_head_revision)

    expect {
      described_class.call(document:)
    }.to change(SchemaWrapper, :count).by(1)

    expect(document.reload.schema_wrapper).to be_present
  end

  it "keeps an existing wrapper for a supported schema document" do
    wrapper = create(:schema_wrapper)

    expect {
      described_class.call(document: wrapper.document)
    }.not_to change(SchemaWrapper, :count)

    expect(wrapper.document.reload.schema_wrapper).to eq(wrapper)
  end

  it "removes the wrapper when the document is no longer a supported schema" do
    wrapper = create(:schema_wrapper)
    revision = create(
      :revision,
      document: wrapper.document,
      parent_revision: wrapper.document.head_revision,
      body: { "title" => "Plain document" }
    )
    wrapper.document.update!(head_revision: revision)

    expect {
      described_class.call(document: wrapper.document)
    }.to change(SchemaWrapper, :count).by(-1)

    expect(wrapper.document.reload.schema_wrapper).to be_nil
  end

  it "does not create a wrapper for unsupported schema declarations" do
    document = create(
      :document,
      :with_head_revision,
      head_body: {
        "$schema" => "https://json-schema.org/draft/1999-09/schema",
        "$id" => "http://example.test/schemas/old",
        "type" => "object"
      }
    )

    expect {
      described_class.call(document:)
    }.not_to change(SchemaWrapper, :count)

    expect(document.reload.schema_wrapper).to be_nil
  end
end
