# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ptr::Cursor do
  let(:schema_body) do
    {
      "type" => "object",
      "properties" => {
        "title" => { "type" => "string", "enum" => [ "Hello", "World" ] },
        "published" => { "type" => "boolean" },
        "count" => { "type" => "integer" },
        "items" => {
          "type" => "array",
          "items" => {
            "type" => "object",
            "required" => [ "name" ],
            "properties" => {
              "name" => { "type" => "string" }
            }
          }
        }
      },
      "required" => [ "title" ]
    }
  end

  let(:body) do
    {
      "title" => "Hello",
      "published" => true,
      "count" => 3,
      "items" => [
        { "name" => "Alpha" }
      ]
    }
  end

  describe ".for" do
    it "builds aligned json and schema pointers" do
      cursor = described_class.for(body:, schema_body:, ptr: "/title")

      expect(cursor.ptr).to eq("/title")
      expect(cursor.schema_ptr).to eq("/properties/title")
      expect(cursor.value).to eq("Hello")
      expect(cursor.schema_node["type"]).to eq("string")
    end
  end

  describe "#root?" do
    it "is true at the root" do
      cursor = described_class.for(body:, schema_body:, ptr: "")

      expect(cursor).to be_root
    end
  end

  describe "#child" do
    it "moves both json and schema locations together" do
      cursor = described_class.for(body:, schema_body:, ptr: "")
      child = cursor.child("title")

      expect(child.ptr).to eq("/title")
      expect(child.schema_ptr).to eq("/properties/title")
      expect(child.value).to eq("Hello")
    end
  end

  describe "#parent" do
    it "returns the parent cursor" do
      cursor = described_class.for(body:, schema_body:, ptr: "/items/0/name")
      parent = cursor.parent

      expect(parent.ptr).to eq("/items/0")
      expect(parent.schema_ptr).to eq("/properties/items/items")
      expect(parent.value).to eq({ "name" => "Alpha" })
    end
  end

  describe "#type" do
    it "uses the schema type when present" do
      cursor = described_class.for(body:, schema_body:, ptr: "/count")

      expect(cursor.type).to eq("integer")
    end
  end

  describe "#enum_values" do
    it "returns enum values from the schema node" do
      cursor = described_class.for(body:, schema_body:, ptr: "/title")

      expect(cursor.enum_values).to eq([ "Hello", "World" ])
    end
  end

  describe "#input_kind" do
    it "uses select for enums" do
      cursor = described_class.for(body:, schema_body:, ptr: "/title")

      expect(cursor.input_kind).to eq(:select)
    end

    it "uses checkbox for booleans" do
      cursor = described_class.for(body:, schema_body:, ptr: "/published")

      expect(cursor.input_kind).to eq(:checkbox)
    end

    it "uses number for integers" do
      cursor = described_class.for(body:, schema_body:, ptr: "/count")

      expect(cursor.input_kind).to eq(:number)
    end
  end

  describe "#required?" do
    it "is true when the parent schema marks the property required" do
      cursor = described_class.for(body:, schema_body:, ptr: "/title")

      expect(cursor).to be_required
    end

    it "is false when the property is not required" do
      cursor = described_class.for(body:, schema_body:, ptr: "/published")

      expect(cursor).not_to be_required
    end
  end

  describe "#array_element?" do
    it "is true for array elements" do
      cursor = described_class.for(body:, schema_body:, ptr: "/items/0")

      expect(cursor).to be_array_element
    end
  end

  describe "#object_property?" do
    it "is true for object properties" do
      cursor = described_class.for(body:, schema_body:, ptr: "/title")

      expect(cursor).to be_object_property
    end
  end

  describe "#children" do
    it "returns schema-driven children for objects" do
      cursor = described_class.for(body:, schema_body:, ptr: "")

      expect(cursor.children.map(&:ptr)).to eq([ "/count", "/items", "/published", "/title" ])
    end

    it "returns indexed children for arrays" do
      cursor = described_class.for(body:, schema_body:, ptr: "/items")

      expect(cursor.children.map(&:ptr)).to eq([ "/items/0" ])
    end
  end

  describe "#seed_item_value" do
    it "returns a seed value for array items" do
      cursor = described_class.for(body:, schema_body:, ptr: "/items")

      expect(cursor.seed_item_value).to be_present
    end
  end
end
