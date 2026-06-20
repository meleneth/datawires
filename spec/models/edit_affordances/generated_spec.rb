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
end
