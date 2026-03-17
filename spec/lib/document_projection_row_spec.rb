# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentProjectionRow do
  subject(:row) { described_class.new(projection:, name:) }

  let(:name) { "title" }
  let(:path) { DocumentPath.new("/metadata") }

  let(:projection) do
    instance_double(
      DocumentProjection,
      child_required?: required,
      child_present?: present,
      child_value: value,
      child_schema: schema,
      path: path
    )
  end

  let(:required) { false }
  let(:present) { false }
  let(:value) { nil }
  let(:schema) { { "type" => "string" } }

  describe "#name" do
    it "returns the property name" do
      expect(row.name).to eq("title")
    end
  end

  describe "#type" do
    it "returns the schema type" do
      expect(row.type).to eq("string")
    end

    context "when schema type is missing" do
      let(:schema) { {} }

      it "returns a fallback label" do
        expect(row.type).to eq("(no type)")
      end
    end
  end

  describe "#required?" do
    let(:required) { true }

    it "delegates to the projection" do
      expect(row.required?).to be(true)
    end
  end

  describe "#present?" do
    let(:present) { true }

    it "delegates to the projection" do
      expect(row.present?).to be(true)
    end
  end

  describe "#value" do
    let(:value) { "Hello" }

    it "delegates to the projection" do
      expect(row.value).to eq("Hello")
    end
  end

  describe "#composite?" do
    context "when type is object" do
      let(:schema) { { "type" => "object" } }

      it "is true" do
        expect(row.composite?).to be(true)
      end
    end

    context "when type is array" do
      let(:schema) { { "type" => "array" } }

      it "is true" do
        expect(row.composite?).to be(true)
      end
    end

    context "when value is a hash" do
      let(:value) { {} }

      it "is true" do
        expect(row.composite?).to be(true)
      end
    end

    context "when value is an array" do
      let(:value) { [] }

      it "is true" do
        expect(row.composite?).to be(true)
      end
    end

    context "when scalar" do
      let(:schema) { { "type" => "string" } }
      let(:value) { "hi" }

      it "is false" do
        expect(row.composite?).to be(false)
      end
    end
  end

  describe "#openable?" do
    context "when composite" do
      let(:schema) { { "type" => "object" } }

      it "is true" do
        expect(row.openable?).to be(true)
      end
    end

    context "when scalar" do
      let(:schema) { { "type" => "string" } }

      it "is false" do
        expect(row.openable?).to be(false)
      end
    end
  end

  describe "#scalar?" do
    context "when scalar" do
      let(:schema) { { "type" => "string" } }

      it "is true" do
        expect(row.scalar?).to be(true)
      end
    end

    context "when composite" do
      let(:schema) { { "type" => "object" } }

      it "is false" do
        expect(row.scalar?).to be(false)
      end
    end
  end

  describe "#input_kind" do
    context "for boolean" do
      let(:schema) { { "type" => "boolean" } }

      it "is checkbox" do
        expect(row.input_kind).to eq(:checkbox)
      end
    end

    context "for integer" do
      let(:schema) { { "type" => "integer" } }

      it "is number" do
        expect(row.input_kind).to eq(:number)
      end
    end

    context "for number" do
      let(:schema) { { "type" => "number" } }

      it "is number" do
        expect(row.input_kind).to eq(:number)
      end
    end

    context "for string" do
      let(:schema) { { "type" => "string" } }

      it "is text" do
        expect(row.input_kind).to eq(:text)
      end
    end
  end

  describe "#field_value" do
    context "when present" do
      let(:present) { true }
      let(:value) { "Hello" }

      it "returns the current value" do
        expect(row.field_value).to eq("Hello")
      end
    end

    context "when missing boolean" do
      let(:schema) { { "type" => "boolean" } }

      it "defaults to false" do
        expect(row.field_value).to be(false)
      end
    end

    context "when missing string" do
      let(:schema) { { "type" => "string" } }

      it "defaults to nil" do
        expect(row.field_value).to be_nil
      end
    end
  end

  describe "#path" do
    it "returns the child path under the projection path" do
      expect(row.path).to be_a(DocumentPath)
      expect(row.path.to_s).to eq("/metadata/title")
    end
  end

  describe "#ptr" do
    it "returns the document pointer for the row path" do
      expect(row.ptr).to eq("/metadata/title")
    end
  end

  describe "#value_label" do
    context "when missing" do
      it "says missing" do
        expect(row.value_label).to eq("missing")
      end
    end

    context "when composite" do
      let(:present) { true }
      let(:schema) { { "type" => "object" } }
      let(:value) { { "nested" => true } }

      it "says present" do
        expect(row.value_label).to eq("present")
      end
    end

    context "when scalar" do
      let(:present) { true }
      let(:value) { "Hello" }

      it "inspects the value" do
        expect(row.value_label).to eq(%("Hello"))
      end
    end
  end
end
