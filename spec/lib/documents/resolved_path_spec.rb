# frozen_string_literal: true

require "rails_helper"

RSpec.describe Documents::ResolvedPath do
  let(:schema_body) do
    {
      "type" => "object",
      "$defs" => {
        "Item" => {
          "type" => "object",
          "properties" => {
            "name" => { "type" => "string" },
            "tags" => {
              "type" => "array",
              "items" => { "type" => "string" }
            }
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

  describe "#schema_node" do
    it "resolves the root schema" do
      resolved = described_class.new(path: "/", schema_body:)

      expect(resolved.schema_node["type"]).to eq("object")
    end

    it "resolves an array property schema" do
      resolved = described_class.new(path: "/items", schema_body:)

      expect(resolved.schema_node["type"]).to eq("array")
      expect(resolved.object_property?).to be(true)
      expect(resolved.array_element?).to be(false)
    end

    it "resolves a $ref for an array item" do
      resolved = described_class.new(path: "/items/0", schema_body:)

      expect(resolved.schema_node["type"]).to eq("object")
      expect(resolved.array_element?).to be(true)
      expect(resolved.object_property?).to be(false)
    end

    it "resolves traversal through a $ref item to a nested property" do
      resolved = described_class.new(path: "/items/0/name", schema_body:)

      expect(resolved.schema_node["type"]).to eq("string")
      expect(resolved.object_property?).to be(true)
      expect(resolved.array_element?).to be(false)
    end

    it "resolves traversal through nested array property under a $ref item" do
      resolved = described_class.new(path: "/items/0/tags/0", schema_body:)

      expect(resolved.schema_node["type"]).to eq("string")
      expect(resolved.array_element?).to be(true)
    end

    it "raises when traversing to an unknown property" do
      expect {
        described_class.new(path: "/items/0/nope", schema_body:).schema_node
      }.to raise_error(Documents::ResolvedPath::InvalidTraversalError)
    end
  end
end
