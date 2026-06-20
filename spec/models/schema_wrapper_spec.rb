# frozen_string_literal: true

require "rails_helper"

RSpec.describe SchemaWrapper, type: :model do
  it "requires the wrapped document to be a supported schema" do
    document = create(
      :document,
      :with_head_revision,
      head_body: {
        "$schema" => "https://json-schema.org/draft/1999-09/schema",
        "$id" => "http://example.test/schemas/old",
        "type" => "object"
      }
    )

    wrapper = described_class.new(document:)

    expect(wrapper).not_to be_valid
    expect(wrapper.errors[:document]).to include("must be a supported schema document")
  end

  describe "#conforming_documents" do
    it "returns only committed documents using the wrapped schema" do
      schema_wrapper = create(:schema_wrapper)
      committed = create(
        :document,
        :with_plain_head_revision,
        domain: schema_wrapper.domain,
        schema_document: schema_wrapper.document
      )
      create(
        :document,
        domain: schema_wrapper.domain,
        schema_document: schema_wrapper.document,
        head_revision: nil
      )

      expect(schema_wrapper.conforming_documents).to contain_exactly(committed)
    end
  end
end
