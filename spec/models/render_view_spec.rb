# frozen_string_literal: true

require "rails_helper"

RSpec.describe RenderView, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:for_schema_document).class_name("Document") }
    it { is_expected.to belong_to(:view_document).class_name("Document") }
  end

  describe "validations" do
    subject(:render_view) { build(:render_view) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:for_schema_document_id) }
  end

  describe "custom validations" do
    let(:schema_document) { create(:document, :with_schema_head_revision) }
    let(:ordinary_document) { create(:document, :with_plain_head_revision) }

    it "is valid when for_schema_document is a schema document" do
      render_view = build(
        :render_view,
        for_schema_document: schema_document
      )

      expect(render_view).to be_valid
    end

    it "is invalid when for_schema_document is not a schema document" do
      render_view = build(
        :render_view,
        for_schema_document: ordinary_document
      )

      expect(render_view).not_to be_valid
      expect(render_view.errors[:for_schema_document]).to include("must be a schema document")
    end

    it "is invalid when view_document equals for_schema_document" do
      render_view = build(
        :render_view,
        for_schema_document: schema_document,
        view_document: schema_document
      )

      expect(render_view).not_to be_valid
      expect(render_view.errors[:view_document]).to include("must be a separate document")
    end
  end
end
