# frozen_string_literal: true

require "rails_helper"

RSpec.describe EditAffordance, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:schema_wrapper).class_name("SchemaWrapper") }
    it { is_expected.to belong_to(:edit_document).class_name("Document") }
  end

  describe "validations" do
    subject(:edit_affordance) { build(:edit_affordance) }

    it { is_expected.to validate_presence_of(:title) }

    it "validates uniqueness of title scoped to schema_wrapper_id" do
      schema_wrapper = create(:schema_wrapper)

      create(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        title: "default"
      )

      duplicate = build(
        :edit_affordance,
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
        :edit_affordance,
        schema_wrapper: first_schema_wrapper,
        title: "default"
      )

      other = build(
        :edit_affordance,
        schema_wrapper: second_schema_wrapper,
        title: "default"
      )

      expect(other).to be_valid
    end
  end

  describe "custom validations" do
    let(:schema_wrapper) { create(:schema_wrapper) }
    let(:edit_document) { create(:document, :with_plain_head_revision) }

    it "is valid when schema_wrapper wraps a schema document" do
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )

      expect(affordance).to be_valid
    end

    it "is invalid when edit_document equals the wrapped schema document" do
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: schema_wrapper.document
      )

      expect(affordance).not_to be_valid
      expect(affordance.errors[:edit_document]).to include("must be a separate document")
    end
  end

  describe "#body" do
    it "returns the upgraded edit document head body" do
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "rows" => []
        }
      )
      affordance = build(:edit_affordance, edit_document: edit_document)

      expect(affordance.body).to eq(
        "version" => 1,
        "rows" => []
      )
    end
  end

  describe "#projection" do
    it "projects bespoke rows into a projection with typed cells" do
      schema_wrapper = create(
        :schema_wrapper,
        document: create(:document, :with_name_schema)
      )
      edit_document = create(
        :document,
        :with_head_revision,
        head_body: {
          "version" => 1,
          "screen" => {
            "columns" => 6
          },
          "rows" => [
            [
              {
                "binding" => {
                  "kind" => "document_ptr",
                  "ptr" => "/name"
                },
                "span" => 3
              },
              {
                "kind" => "commit",
                "span" => 3,
                "message_mode" => "inline_optional"
              }
            ]
          ]
        }
      )
      affordance = build(
        :edit_affordance,
        schema_wrapper: schema_wrapper,
        edit_document: edit_document
      )
      draft = build(
        :draft,
        document: build(:document, schema_document: schema_wrapper.document),
        body: {}
      )
      cursor = Documents::Cursor.new(source: draft, path: "")

      projection = affordance.projection(cursor)
      cells = projection.rows.flat_map(&:cells)

      expect(projection).to be_a(EditAffordances::Projection)
      expect(projection.defaults.column_count).to eq(6)
      expect(cells.first).to be_a(EditAffordances::Cells::Field)
      expect(cells.second).to be_a(EditAffordances::Cells::Commit)
    end
  end
end
