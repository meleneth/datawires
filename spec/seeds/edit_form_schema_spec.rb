# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/edit_form_schema")

RSpec.describe Seeds::EditFormSchema do
  describe ".schema_body" do
    it "allows every currently supported field widget" do
      widget_enum = described_class
        .schema_body
        .fetch("$defs")
        .fetch("field_cell")
        .fetch("properties")
        .fetch("widget")
        .fetch("enum")

      expect(widget_enum).to contain_exactly(
        "array",
        "auto",
        "checkbox",
        "number",
        "select",
        "text",
        "textarea"
      )
    end

    it "allows field metadata supported by projection" do
      field_properties = described_class
        .schema_body
        .fetch("$defs")
        .fetch("field_cell")
        .fetch("properties")

      expect(field_properties.fetch("help")).to eq("type" => "string")
      expect(field_properties.fetch("placeholder")).to eq("type" => "string")
      expect(field_properties.fetch("display")).to include(
        "type" => "object",
        "additionalProperties" => false
      )
      expect(field_properties.dig("display", "properties", "compact")).to eq("type" => "boolean")
      expect(field_properties.dig("display", "properties", "readonly")).to eq("type" => "boolean")
    end

    it "allows the current collection config shape" do
      definitions = described_class.schema_body.fetch("$defs")
      collection_properties = definitions
        .fetch("collection")
        .fetch("properties")

      expect(collection_properties.dig("behavior", "enum")).to eq([ "list_open" ])
      expect(collection_properties.dig("presentation", "enum")).to eq([ "list" ])
      expect(collection_properties.dig("creation", "enum")).to eq([ "append_and_open" ])
      expect(collection_properties.dig("navigation", "enum")).to eq([ "open_item" ])
      expect(collection_properties.dig("delete", "enum")).to eq([ "disabled" ])
      expect(collection_properties.dig("reorder", "enum")).to eq([ "disabled" ])
      expect(definitions.dig("collection_binding", "properties", "kind", "enum")).to contain_exactly(
        "none",
        "property",
        "value_label"
      )
    end
  end
end
