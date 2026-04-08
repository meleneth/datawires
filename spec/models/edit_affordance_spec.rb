# frozen_string_literal: true

require "rails_helper"

RSpec.describe EditAffordance, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:for_schema_document).class_name("Document") }
    it { is_expected.to belong_to(:affordance_document).class_name("Document") }
  end

  describe "validations" do
    subject(:edit_affordance) { build(:edit_affordance) }

    it { is_expected.to validate_presence_of(:name) }

    it "validates uniqueness of name scoped to for_schema_document_id" do
      create(:edit_affordance, name: "default")

      expect(build(:edit_affordance, name: "default"))
        .not_to be_valid
    end
  end

  describe "custom validations" do
    let(:schema_document) { create(:document, :with_schema_head_revision) }
    let(:ordinary_document) { create(:document, :with_plain_head_revision) }
    let(:affordance_document) { create(:document, :with_plain_head_revision) }

    it "is valid when for_schema_document is a schema document" do
      affordance = build(
        :edit_affordance,
        for_schema_document: schema_document,
        affordance_document: affordance_document
      )

      expect(affordance).to be_valid
    end

    it "is invalid when for_schema_document is not a schema document" do
      affordance = build(
        :edit_affordance,
        for_schema_document: ordinary_document,
        affordance_document: affordance_document
      )

      expect(affordance).not_to be_valid
      expect(affordance.errors[:for_schema_document]).to include("must be a schema document")
    end

    it "is invalid when affordance_document equals for_schema_document" do
      affordance = build(
        :edit_affordance,
        for_schema_document: schema_document,
        affordance_document: schema_document
      )

      expect(affordance).not_to be_valid
      expect(affordance.errors[:affordance_document]).to include("must be a separate document")
    end
  end
end
