# frozen_string_literal: true

require "rails_helper"

RSpec.describe EditAffordances::Generated do
  it "projects immediate schema properties as editable fields" do
    schema_wrapper = create(
      :schema_wrapper,
      document: create(:document, :with_name_schema)
    )
    draft = build(
      :draft,
      document: build(:document, schema_document: schema_wrapper.document),
      body: {}
    )
    cursor = Documents::Cursor.new(source: draft, path: "")

    affordance = described_class.new(schema_wrapper:)

    rows = affordance.projected_rows(cursor)

    expect(rows.length).to eq(schema_wrapper.document.body.fetch("properties").length)
    expect(rows.flat_map(&:cells).map(&:cursor).map(&:name)).to match_array(
      schema_wrapper.document.body.fetch("properties").keys
    )
  end

  it "uses schema path inventory metadata for generated array widgets" do
    schema_wrapper = create(
      :schema_wrapper,
      document: create(
        :document,
        :with_head_revision,
        head_body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "http://example.test/schemas/list",
          "type" => "object",
          "properties" => {
            "items" => {
              "type" => "array",
              "items" => {
                "type" => "string"
              }
            }
          }
        }
      )
    )
    draft = build(
      :draft,
      document: build(:document, schema_document: schema_wrapper.document),
      body: {}
    )
    cursor = Documents::Cursor.new(source: draft, path: "")

    rows = described_class.new(schema_wrapper:).projected_rows(cursor)

    expect(rows.flat_map(&:cells).first.widget).to eq("array")
  end

  it "projects generated rows into a projection with typed cells" do
    schema_wrapper = create(
      :schema_wrapper,
      document: create(
        :document,
        :with_head_revision,
        head_body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "http://example.test/schemas/generated",
          "type" => "object",
          "properties" => {
            "name" => { "type" => "string" },
            "metadata" => {
              "type" => "object",
              "properties" => {
                "notes" => { "type" => "string" }
              }
            },
            "items" => {
              "type" => "array",
              "items" => { "type" => "string" }
            }
          }
        }
      )
    )
    draft = build(
      :draft,
      document: build(:document, schema_document: schema_wrapper.document),
      body: {}
    )
    cursor = Documents::Cursor.new(source: draft, path: "")

    projection = described_class.new(schema_wrapper:).projection(cursor)
    cells = projection.rows.flat_map(&:cells)

    expect(projection).to be_a(EditAffordances::Projection)
    expect(cells).to include(
      an_instance_of(EditAffordances::Cells::Field),
      an_instance_of(EditAffordances::Cells::Section),
      an_instance_of(EditAffordances::Cells::Array)
    )
  end
end
