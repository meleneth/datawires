# frozen_string_literal: true

require "rails_helper"

RSpec.describe Documents::SchemaResolver do
  subject(:resolver) { described_class.new(root_schema:) }

  let(:root_schema) do
    {
      "$defs" => {
        "Item" => {
          "type" => "object",
          "properties" => {
            "name" => { "type" => "string" }
          }
        },
        "ItemAlias" => {
          "$ref" => "#/$defs/Item"
        }
      }
    }
  end

  describe "#resolve" do
    it "returns plain nodes unchanged" do
      node = { "type" => "string" }

      expect(resolver.resolve(node)).to eq(node)
    end

    it "resolves an internal $ref" do
      node = { "$ref" => "#/$defs/Item" }

      expect(resolver.resolve(node)).to eq(root_schema.fetch("$defs").fetch("Item"))
    end

    it "resolves chained internal $ref values" do
      node = { "$ref" => "#/$defs/ItemAlias" }

      expect(resolver.resolve(node)).to eq(root_schema.fetch("$defs").fetch("Item"))
    end

    it "raises for unsupported external refs" do
      node = { "$ref" => "https://example.com/schema.json#/foo" }

      expect { resolver.resolve(node) }
        .to raise_error(Documents::SchemaResolver::UnsupportedRefError)
    end

    it "raises for circular refs" do
      circular_root = {
        "$defs" => {
          "LoopA" => { "$ref" => "#/$defs/LoopB" },
          "LoopB" => { "$ref" => "#/$defs/LoopA" }
        }
      }

      circular_resolver = described_class.new(root_schema: circular_root)

      expect {
        circular_resolver.resolve({ "$ref" => "#/$defs/LoopA" })
      }.to raise_error(Documents::SchemaResolver::CircularRefError)
    end
  end
end
