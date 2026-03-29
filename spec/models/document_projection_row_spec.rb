# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentProjectionRow do
  subject(:row) { described_class.new(projection:, name:) }

  let(:name) { "character_class" }
  let(:child_path) { instance_double(DocumentPath, document_ptr: "/character_class") }
  let(:path) { instance_double(DocumentPath, child: child_path) }

  let(:projection) do
    instance_double(
      DocumentProjection,
      source: draft,
      child_schema: schema_node,
      child_required?: false,
      child_present?: present,
      child_value: value,
      path:
    )
  end

  let(:draft) { instance_double(Draft) }
  let(:present) { false }
  let(:value) { nil }
  let(:schema_node) { { "type" => "string" } }

  describe "#input_kind" do
    context "when schema has enum" do
      let(:schema_node) { { "type" => "string", "enum" => %w[Warlock Sorceress] } }

      it "returns :select" do
        expect(row.input_kind).to eq(:select)
      end
    end

    context "when schema type is boolean" do
      let(:schema_node) { { "type" => "boolean" } }

      it "returns :checkbox" do
        expect(row.input_kind).to eq(:checkbox)
      end
    end

    context "when schema type is integer" do
      let(:schema_node) { { "type" => "integer" } }

      it "returns :number" do
        expect(row.input_kind).to eq(:number)
      end
    end

    context "when schema type is number" do
      let(:schema_node) { { "type" => "number" } }

      it "returns :number" do
        expect(row.input_kind).to eq(:number)
      end
    end

    context "when schema type is plain string" do
      it "returns :text" do
        expect(row.input_kind).to eq(:text)
      end
    end
  end

  describe "#field_value" do
    context "when a value is present" do
      let(:present) { true }
      let(:value) { "Warlock" }

      it "returns the value" do
        expect(row.field_value).to eq("Warlock")
      end
    end

    context "when checkbox value is missing" do
      let(:schema_node) { { "type" => "boolean" } }

      it "defaults to false" do
        expect(row.field_value).to eq(false)
      end
    end

    context "when select value is missing" do
      let(:schema_node) { { "type" => "string", "enum" => %w[Boyle Another] } }

      it "defaults to nil" do
        expect(row.field_value).to be_nil
      end
    end

    context "when text value is missing" do
      it "defaults to nil" do
        expect(row.field_value).to be_nil
      end
    end
  end

  describe "#enum_values" do
    let(:schema_node) { { "type" => "string", "enum" => %w[Boyle Another] } }

    it "returns the enum values" do
      expect(row.enum_values).to eq(%w[Boyle Another])
    end
  end

  describe "#draft" do
    it "returns the projection source" do
      expect(row.draft).to eq(draft)
    end
  end

  describe "#ptr" do
    it "returns the child document pointer" do
      expect(row.ptr).to eq("/character_class")
    end
  end
end
