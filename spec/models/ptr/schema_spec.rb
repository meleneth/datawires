# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ptr::Schema do
  let(:schema_body) do
    {
      "type" => "object",
      "properties" => {
        "title" => { "type" => "string" },
        "items" => {
          "type" => "array",
          "items" => {
            "type" => "object",
            "properties" => {
              "name" => { "type" => "string" }
            }
          }
        }
      }
    }
  end

  describe ".root" do
    it "builds a root schema pointer" do
      ptr = described_class.root(schema: schema_body)

      expect(ptr.ptr).to eq("")
      expect(ptr).to be_root
      expect(ptr.node).to eq(schema_body)
    end
  end

  describe ".from_json" do
    it "maps a top-level property json ptr to schema space" do
      json = Ptr::Json.new(body: { "title" => "Hello" }, ptr: "/title")

      schema = described_class.from_json(json:, schema: schema_body)

      expect(schema.ptr).to eq("/properties/title")
      expect(schema.node).to eq({ "type" => "string" })
    end

    it "maps an array element json ptr to the items schema" do
      json = Ptr::Json.new(body: { "items" => [ { "name" => "A" } ] }, ptr: "/items/0")

      schema = described_class.from_json(json:, schema: schema_body)

      expect(schema.ptr).to eq("/properties/items/items")
      expect(schema.node["type"]).to eq("object")
    end

    it "maps a nested property within an array element" do
      json = Ptr::Json.new(body: { "items" => [ { "name" => "A" } ] }, ptr: "/items/0/name")

      schema = described_class.from_json(json:, schema: schema_body)

      expect(schema.ptr).to eq("/properties/items/items/properties/name")
      expect(schema.node).to eq({ "type" => "string" })
    end

    it "raises when traversing a missing object property" do
      json = Ptr::Json.new(body: { "subtitle" => "Nope" }, ptr: "/subtitle")

      expect do
        described_class.from_json(json:, schema: schema_body)
      end.to raise_error(Ptr::Schema::InvalidTraversalError)
    end

    it "raises when traversing an array with a non-integer token" do
      json = Ptr::Json.new(body: { "items" => [] }, ptr: "/items/nope")

      expect do
        described_class.from_json(json:, schema: schema_body)
      end.to raise_error(Ptr::Schema::InvalidTraversalError)
    end
  end

  describe "#object?" do
    it "is true for object schemas" do
      ptr = described_class.new(schema: schema_body, ptr: "")

      expect(ptr).to be_object
    end
  end

  describe "#array?" do
    it "is true for array schemas" do
      ptr = described_class.new(schema: schema_body, ptr: "/properties/items")

      expect(ptr).to be_array
    end
  end

  describe "#child_property" do
    it "returns the child property schema pointer" do
      ptr = described_class.new(schema: schema_body, ptr: "")

      child = ptr.child_property("title")

      expect(child.ptr).to eq("/properties/title")
      expect(child.node).to eq({ "type" => "string" })
    end
  end

  describe "#child_item" do
    it "returns the items schema pointer" do
      ptr = described_class.new(schema: schema_body, ptr: "/properties/items")

      child = ptr.child_item

      expect(child.ptr).to eq("/properties/items/items")
      expect(child.node["type"]).to eq("object")
    end
  end

  describe "#children" do
    it "returns property children for object schemas" do
      ptr = described_class.new(schema: schema_body, ptr: "")

      expect(ptr.children.map(&:ptr)).to eq([ "/properties/items", "/properties/title" ])
    end

    it "returns the item child for array schemas" do
      ptr = described_class.new(schema: schema_body, ptr: "/properties/items")

      expect(ptr.children.map(&:ptr)).to eq([ "/properties/items/items" ])
    end
  end
end
