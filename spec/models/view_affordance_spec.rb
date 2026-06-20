# frozen_string_literal: true

require "rails_helper"

RSpec.describe ViewAffordance, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:schema_wrapper).class_name("SchemaWrapper") }
    it { is_expected.to belong_to(:view_document).class_name("Document") }
  end

  describe "validations" do
    subject(:view_affordance) { build(:view_affordance) }

    it { is_expected.to validate_presence_of(:title) }

    it "validates uniqueness of title scoped to schema_wrapper_id" do
      schema_wrapper = create(:schema_wrapper)

      create(
        :view_affordance,
        schema_wrapper: schema_wrapper,
        title: "default"
      )

      duplicate = build(
        :view_affordance,
        schema_wrapper: schema_wrapper,
        title: "default"
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:title]).to include("has already been taken")
    end

    it "allows the same title for a different schema wrapper" do
      first_schema_wrapper = create(:schema_wrapper)
      second_schema_wrapper = create(:schema_wrapper)

      create(
        :view_affordance,
        schema_wrapper: first_schema_wrapper,
        title: "default"
      )

      other = build(
        :view_affordance,
        schema_wrapper: second_schema_wrapper,
        title: "default"
      )

      expect(other).to be_valid
    end
  end

  describe "custom validations" do
    let(:schema_wrapper) { create(:schema_wrapper) }
    let(:view_document) { create(:document, :with_plain_head_revision) }

    it "is valid when schema_wrapper wraps a schema document" do
      view_affordance = build(
        :view_affordance,
        schema_wrapper: schema_wrapper,
        view_document: view_document
      )

      expect(view_affordance).to be_valid
    end

    it "is invalid when view_document equals the wrapped schema document" do
      view_affordance = build(
        :view_affordance,
        schema_wrapper: schema_wrapper,
        view_document: schema_wrapper.document
      )

      expect(view_affordance).not_to be_valid
      expect(view_affordance.errors[:view_document]).to include("must be a separate document")
    end
  end
end
