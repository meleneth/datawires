# frozen_string_literal: true

require "rails_helper"

RSpec.describe Documents::Projection do
  let(:schema_document) { instance_double(Document, body: schema_body) }
  let(:draft) do
    instance_double(
      Draft,
      body: body,
      schema_document:
    )
  end

  let(:schema_body) do
    {
      "type" => "object",
      "properties" => {
        "title" => { "type" => "string" },
        "items" => {
          "type" => "array",
          "items" => { "type" => "string" }
        }
      }
    }
  end

  let(:body) do
    {
      "title" => "Hello",
      "items" => [ "a" ]
    }
  end

  it "classifies object locations" do
    projection = described_class.new(source: draft, path: "/")

    expect(projection.location_kind).to eq(:object)
    expect(projection.cursor.path.to_s).to eq("")
  end

  it "classifies array locations" do
    projection = described_class.new(source: draft, path: "/items")

    expect(projection.location_kind).to eq(:array)
  end

  it "classifies scalar locations" do
    projection = described_class.new(source: draft, path: "/title")

    expect(projection.location_kind).to eq(:scalar)
  end
end
