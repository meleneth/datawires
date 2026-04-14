# frozen_string_literal: true

require "rails_helper"

RSpec.describe EditAffordance, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:for_schema_document).class_name("SchemaDocument") }
    it { is_expected.to belong_to(:edit_document).class_name("Document") }
  end

  describe "validations" do
    subject(:edit_affordance) { build(:edit_affordance) }

    it { is_expected.to validate_presence_of(:title) }

    it "validates uniqueness of title scoped to for_schema_document_id" do
      schema_document = create(:schema_document)

      create(
        :edit_affordance,
        for_schema_document: schema_document,
        title: "default"
      )

      duplicate = build(
        :edit_affordance,
        for_schema_document: schema_document,
        title: "default"
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:title]).to include("has already been taken")
    end

    it "allows the same title for a different schema document" do
      first_schema_document = create(:schema_document)
      second_schema_document = create(:schema_document)

      create(
        :edit_affordance,
        for_schema_document: first_schema_document,
        title: "default"
      )

      other = build(
        :edit_affordance,
        for_schema_document: second_schema_document,
        title: "default"
      )

      expect(other).to be_valid
    end
  end

  describe "custom validations" do
    let(:schema_document) { create(:schema_document) }
    let(:edit_document) { create(:document, :with_plain_head_revision) }

    it "is valid when for_schema_document is a schema document" do
      affordance = build(
        :edit_affordance,
        for_schema_document: schema_document,
        edit_document: edit_document
      )

      expect(affordance).to be_valid
    end

    it "is invalid when edit_document equals the wrapped schema document" do
      affordance = build(
        :edit_affordance,
        for_schema_document: schema_document,
        edit_document: schema_document.document
      )

      expect(affordance).not_to be_valid
      expect(affordance.errors[:edit_document]).to include("must be a separate document")
    end
  end
end
