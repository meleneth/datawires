# frozen_string_literal: true

require "rails_helper"

RSpec.describe Documents::Cursor do
  subject(:cursor) { described_class.new(source: draft, path:) }

  let(:draft) { instance_double(Draft, body:, schema_document:) }
  let(:schema_document) { instance_double(Document, body: schema_body) }

  let(:path) { Documents::Path.new("/metadata/title") }
  let(:body) { {} }
  let(:schema_body) do
    {
      "type" => "object",
      "properties" => {
        "metadata" => {
          "type" => "object",
          "required" => [ "title" ],
          "properties" => {
            "title" => { "type" => "string" }
          }
        }
      }
    }
  end

  describe "#draft" do
    it "returns the source" do
      expect(cursor.draft).to eq(draft)
    end
  end

  describe "#ptr" do
    it "returns the document pointer" do
      expect(cursor.ptr).to eq("/metadata/title")
    end
  end

  describe "#name" do
    it "returns the final token" do
      expect(cursor.name).to eq("title")
    end
  end

  describe "#parent" do
    it "returns a cursor for the parent path" do
      expect(cursor.parent).to be_a(described_class)
      expect(cursor.parent.path.to_s).to eq("/metadata")
    end

    context "when at root" do
      let(:path) { Documents::Path.root }

      it "returns nil" do
        expect(cursor.parent).to be_nil
      end
    end
  end

  describe "#child" do
    let(:path) { Documents::Path.new("/metadata") }

    it "returns a cursor for the child path" do
      expect(cursor.child("title")).to be_a(described_class)
      expect(cursor.child("title").path.to_s).to eq("/metadata/title")
    end
  end

  describe "#schema_node" do
    it "returns the resolved schema node" do
      expect(cursor.schema_node).to eq({ "type" => "string" })
    end
  end

  describe "#enum_values" do
    context "when enum is present" do
      let(:schema_body) do
        {
          "type" => "object",
          "properties" => {
            "metadata" => {
              "type" => "object",
              "properties" => {
                "title" => {
                  "type" => "string",
                  "enum" => %w[draft published]
                }
              }
            }
          }
        }
      end

      it "returns the enum values" do
        expect(cursor.enum_values).to eq(%w[draft published])
      end
    end

    context "when enum is absent" do
      it "returns nil" do
        expect(cursor.enum_values).to be_nil
      end
    end
  end

  describe "#type" do
    it "returns the schema type" do
      expect(cursor.type).to eq("string")
    end

    context "when schema type is missing and value is a hash" do
      let(:body) { { "metadata" => { "title" => { "nested" => true } } } }
      let(:schema_body) do
        {
          "type" => "object",
          "properties" => {
            "metadata" => {
              "type" => "object",
              "properties" => {
                "title" => {}
              }
            }
          }
        }
      end

      it "infers object" do
        expect(cursor.type).to eq("object")
      end
    end

    context "when schema type is missing and value is an array" do
      let(:body) { { "metadata" => { "title" => [ 1, 2 ] } } }
      let(:schema_body) do
        {
          "type" => "object",
          "properties" => {
            "metadata" => {
              "type" => "object",
              "properties" => {
                "title" => {}
              }
            }
          }
        }
      end

      it "infers array" do
        expect(cursor.type).to eq("array")
      end
    end

    context "when schema type is missing and value is scalar" do
      let(:body) { { "metadata" => { "title" => "Hello" } } }
      let(:schema_body) do
        {
          "type" => "object",
          "properties" => {
            "metadata" => {
              "type" => "object",
              "properties" => {
                "title" => {}
              }
            }
          }
        }
      end

      it "returns fallback text" do
        expect(cursor.type).to eq("(no type)")
      end
    end
  end

  describe "#required?" do
    it "is true when the parent schema requires the field" do
      expect(cursor.required?).to be(true)
    end

    context "when not required" do
      let(:schema_body) do
        {
          "type" => "object",
          "properties" => {
            "metadata" => {
              "type" => "object",
              "properties" => {
                "title" => { "type" => "string" }
              }
            }
          }
        }
      end

      it "is false" do
        expect(cursor.required?).to be(false)
      end
    end
  end

  describe "#present?" do
    context "when object property exists" do
      let(:body) { { "metadata" => { "title" => "Hello" } } }

      it "is true" do
        expect(cursor.present?).to be(true)
      end
    end

    context "when object property is missing" do
      let(:body) { { "metadata" => {} } }

      it "is false" do
        expect(cursor.present?).to be(false)
      end
    end

    context "when symbol key exists" do
      let(:body) { { "metadata" => { title: "Hello" } } }

      it "is true" do
        expect(cursor.present?).to be(true)
      end
    end

    context "when at root" do
      let(:path) { Documents::Path.root }

      it "is true" do
        expect(cursor.present?).to be(true)
      end
    end

    context "when array element exists" do
      let(:path) { Documents::Path.new("/items/1") }
      let(:body) { { "items" => [ "a", "b", "c" ] } }
      let(:schema_body) do
        {
          "type" => "object",
          "properties" => {
            "items" => {
              "type" => "array",
              "items" => { "type" => "string" }
            }
          }
        }
      end

      it "is true" do
        expect(cursor.present?).to be(true)
      end
    end
  end

  describe "#value" do
    let(:body) { { "metadata" => { "title" => "Hello" } } }

    it "returns the value at the path" do
      expect(cursor.value).to eq("Hello")
    end
  end

  describe "#object?" do
    context "when schema says object" do
      let(:path) { Documents::Path.new("/metadata") }

      it "is true" do
        expect(cursor.object?).to be(true)
      end
    end

    context "when value is a hash" do
      let(:body) { { "metadata" => { "title" => { "nested" => true } } } }
      let(:schema_body) do
        {
          "type" => "object",
          "properties" => {
            "metadata" => {
              "type" => "object",
              "properties" => {
                "title" => {}
              }
            }
          }
        }
      end

      it "is true" do
        expect(cursor.object?).to be(true)
      end
    end
  end

  describe "#array?" do
    context "when schema says array" do
      let(:path) { Documents::Path.new("/items") }
      let(:schema_body) do
        {
          "type" => "object",
          "properties" => {
            "items" => {
              "type" => "array",
              "items" => { "type" => "string" }
            }
          }
        }
      end

      it "is true" do
        expect(cursor.array?).to be(true)
      end
    end
  end

  describe "#composite?" do
    context "when object" do
      let(:path) { Documents::Path.new("/metadata") }

      it "is true" do
        expect(cursor.composite?).to be(true)
      end
    end

    context "when scalar" do
      let(:body) { { "metadata" => { "title" => "Hello" } } }

      it "is false" do
        expect(cursor.composite?).to be(false)
      end
    end
  end

  describe "#openable?" do
    context "when object" do
      let(:path) { Documents::Path.new("/metadata") }

      it "is true" do
        expect(cursor.openable?).to be(true)
      end
    end

    context "when array" do
      let(:path) { Documents::Path.new("/items") }
      let(:schema_body) do
        {
          "type" => "object",
          "properties" => {
            "items" => {
              "type" => "array",
              "items" => { "type" => "string" }
            }
          }
        }
      end

      it "is false" do
        expect(cursor.openable?).to be(false)
      end
    end
  end

  describe "#scalar?" do
    it "is true for scalar values" do
      expect(cursor.scalar?).to be(true)
    end
  end

  describe "#input_kind" do
    context "when enum is present" do
      let(:schema_body) do
        {
          "type" => "object",
          "properties" => {
            "metadata" => {
              "type" => "object",
              "properties" => {
                "title" => {
                  "type" => "string",
                  "enum" => %w[draft published]
                }
              }
            }
          }
        }
      end

      it "returns :select" do
        expect(cursor.input_kind).to eq(:select)
      end
    end

    context "when boolean" do
      let(:schema_body) do
        {
          "type" => "object",
          "properties" => {
            "metadata" => {
              "type" => "object",
              "properties" => {
                "title" => { "type" => "boolean" }
              }
            }
          }
        }
      end

      it "returns :checkbox" do
        expect(cursor.input_kind).to eq(:checkbox)
      end
    end
  end

  describe "#field_value" do
    context "when present" do
      let(:body) { { "metadata" => { "title" => "Hello" } } }

      it "returns the current value" do
        expect(cursor.field_value).to eq("Hello")
      end
    end

    context "when missing boolean" do
      let(:schema_body) do
        {
          "type" => "object",
          "properties" => {
            "metadata" => {
              "type" => "object",
              "properties" => {
                "title" => { "type" => "boolean" }
              }
            }
          }
        }
      end

      it "defaults to false" do
        expect(cursor.field_value).to be(false)
      end
    end
  end

  describe "#checkbox_value" do
    let(:body) { { "metadata" => { "title" => "1" } } }

    it "casts field_value to boolean" do
      expect(cursor.checkbox_value).to be(true)
    end
  end

  describe "#value_label" do
    context "when missing" do
      it "returns missing" do
        expect(cursor.value_label).to eq("missing")
      end
    end

    context "when object" do
      let(:path) { Documents::Path.new("/metadata") }
      let(:body) { { "metadata" => {} } }

      it "returns present" do
        expect(cursor.value_label).to eq("present")
      end
    end

    context "when array" do
      let(:path) { Documents::Path.new("/items") }
      let(:body) { { "items" => [ 1, 2, 3 ] } }
      let(:schema_body) do
        {
          "type" => "object",
          "properties" => {
            "items" => {
              "type" => "array",
              "items" => { "type" => "integer" }
            }
          }
        }
      end

      it "returns item count" do
        expect(cursor.value_label).to eq("3 items")
      end
    end

    context "when scalar" do
      let(:body) { { "metadata" => { "title" => "Hello" } } }

      it "inspects the value" do
        expect(cursor.value_label).to eq(%("Hello"))
      end
    end
  end

  describe "#schema_child_keys" do
    let(:path) { Documents::Path.new("/metadata") }

    it "returns sorted property keys" do
      expect(cursor.schema_child_keys).to eq([ "title" ])
    end
  end

  describe "#children" do
    context "when object" do
      let(:path) { Documents::Path.new("/metadata") }

      it "returns child cursors for schema properties" do
        expect(cursor.children.map(&:ptr)).to eq([ "/metadata/title" ])
      end
    end

    context "when array" do
      let(:path) { Documents::Path.new("/items") }
      let(:body) { { "items" => %w[a b] } }
      let(:schema_body) do
        {
          "type" => "object",
          "properties" => {
            "items" => {
              "type" => "array",
              "items" => { "type" => "string" }
            }
          }
        }
      end

      it "returns child cursors for existing indexes" do
        expect(cursor.children.map(&:ptr)).to eq([ "/items/0", "/items/1" ])
      end
    end

    context "when scalar" do
      let(:body) { { "metadata" => { "title" => "Hello" } } }

      it "returns an empty array" do
        expect(cursor.children).to eq([])
      end
    end
  end
end
