# frozen_string_literal: true

require "rails_helper"

RSpec.describe SchemaWrapper, type: :model do
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
