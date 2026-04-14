# frozen_string_literal: true

require "rails_helper"

RSpec.describe Documents::Cursor do
  let(:schema_body) do
    {
      "type" => "object",
      "$defs" => {
        "Item" => {
          "type" => "object",
          "properties" => {
            "name" => { "type" => "string" }
          }
        }
      },
      "properties" => {
        "items" => {
          "type" => "array",
          "items" => { "$ref" => "#/$defs/Item" }
        }
      }
    }
  end

  let(:schema_document) { instance_double(Document, body: schema_body) }
  let(:draft) do
    instance_double(
      Draft,
      body: { "items" => [ { "name" => "Ayla" } ] },
      schema_document:
    )
  end

  it "resolves type through $ref during traversal" do
    cursor = described_class.new(source: draft, path: "/items/0/name")

    expect(cursor.type).to eq("string")
    expect(cursor.value).to eq("Ayla")
  end
end
