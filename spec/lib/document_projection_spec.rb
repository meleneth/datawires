# spec/lib/document_projection_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentProjection do
  subject(:projection) { described_class.new(source:, path:) }

  let(:path) { DocumentPath.new(raw_path) }

  let(:schema_body) do
    {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "$id" => "http://example.test/schemas/berp",
      "type" => "object",
      "properties" => {
        "mobilis" => {
          "type" => "object",
          "properties" => {
            "name" => { "type" => "string" }
          }
        },
        "vuemaker" => {
          "type" => "object",
          "properties" => {}
        }
      }
    }
  end

  let(:document_body) do
    {
      "mobilis" => {
        "name" => "slug reactor"
      }
    }
  end

  let(:schema_document) do
    instance_double(Document, body: schema_body)
  end

  let(:source) do
    instance_double("DraftLike", body: document_body, schema_document:)
  end

  describe "#document_node" do
    context "when path is root" do
      let(:raw_path) { "/" }

      it "returns the root document node" do
        expect(projection.document_node).to eq(document_body)
      end
    end

    context "when path points at a nested document field" do
      let(:raw_path) { "/mobilis/name" }

      it "returns the nested document value" do
        expect(projection.document_node).to eq("slug reactor")
      end
    end
  end

  describe "#schema_node" do
    context "when path is root" do
      let(:raw_path) { "/" }

      it "returns the root schema node" do
        expect(projection.schema_node).to eq(schema_body)
      end
    end

    context "when path points at a top-level property" do
      let(:raw_path) { "/mobilis" }

      it "projects into schema properties" do
        expect(projection.schema_node).to eq(
          {
            "type" => "object",
            "properties" => {
              "name" => { "type" => "string" }
            }
          }
        )
      end
    end

    context "when path points at a nested property" do
      let(:raw_path) { "/mobilis/name" }

      it "returns the nested schema node" do
        expect(projection.schema_node).to eq(
          { "type" => "string" }
        )
      end
    end
  end

  describe "#root?" do
    context "when path is root" do
      let(:raw_path) { "/" }

      it "returns true" do
        expect(projection.root?).to be(true)
      end
    end

    context "when path is not root" do
      let(:raw_path) { "/mobilis" }

      it "returns false" do
        expect(projection.root?).to be(false)
      end
    end
  end

  describe "source protocol" do
    let(:raw_path) { "/" }

    it "works with any source responding to body and schema_document" do
      plain_ruby_source = Struct.new(:body, :schema_document).new(document_body, schema_document)

      projection = described_class.new(source: plain_ruby_source, path: path)

      expect(projection.document_node).to eq(document_body)
      expect(projection.schema_node).to eq(schema_body)
    end
  end
end
