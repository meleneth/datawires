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
      expect(collection_properties.dig("presentation", "enum")).to contain_exactly("cards", "list", "table")
      expect(collection_properties.dig("creation", "enum")).to contain_exactly(
        "append_and_open",
        "inline_blank_form",
        "new_screen"
      )
      expect(collection_properties.dig("navigation", "enum")).to eq([ "open_item" ])
      expect(collection_properties.dig("delete", "enum")).to contain_exactly("disabled", "enabled")
      expect(collection_properties.dig("reorder", "enum")).to contain_exactly("disabled", "enabled")
      expect(collection_properties.fetch("item_screen")).to include(
        "type" => "string",
        "minLength" => 1
      )
      expect(definitions.dig("collection_binding", "properties", "kind", "enum")).to contain_exactly(
        "none",
        "property",
        "reference_label",
        "value_label"
      )
      expect(definitions.dig("collection_binding", "properties", "schema_key_property")).to include("type" => "string")
      expect(definitions.dig("collection_binding", "properties", "key_property")).to include("type" => "string")
    end

    it "allows screens, subforms, navigation cells, and commit modes" do
      definitions = described_class.schema_body.fetch("$defs")
      properties = described_class.schema_body.fetch("properties")

      expect(properties.fetch("screens")).to include("type" => "array")
      expect(properties.fetch("subforms")).to include("type" => "array")
      expect(properties.fetch("indexes")).to include("type" => "array")
      expect(properties.fetch("commit_mode")).to eq("$ref" => "#/$defs/commit_mode")
      expect(properties.fetch("width")).to eq("$ref" => "#/$defs/width")
      expect(definitions.dig("width", "enum")).to contain_exactly("full", "large", "medium", "narrow")
      expect(definitions.dig("commit_mode", "enum")).to contain_exactly("immediate", "review_screen")
      expect(definitions.fetch("screen").fetch("properties")).to include(
        "root_binding" => {
          "$ref" => "#/$defs/binding"
        },
        "subform" => {
          "type" => "string",
          "minLength" => 1
        }
      )
      expect(definitions.fetch("subform").fetch("properties")).to include(
        "rows" => {
          "$ref" => "#/$defs/rows"
        }
      )
      expect(definitions.dig("field_cell", "properties", "span")).to include(
        "minimum" => 1,
        "maximum" => 12
      )
      expect(definitions.dig("screen", "properties", "default_span")).to include(
        "minimum" => 1,
        "maximum" => 12
      )
      expect(definitions.dig("navigation_cell", "required")).to contain_exactly("kind", "target_screen")
      expect(definitions.dig("commit_cell", "properties", "commit_mode")).to eq("$ref" => "#/$defs/commit_mode")
      expect(definitions.dig("cell", "oneOf")).to include("$ref" => "#/$defs/navigation_cell")
    end

    it "allows configured index definitions" do
      definitions = described_class.schema_body.fetch("$defs")

      expect(definitions.fetch("index_definition")).to include(
        "type" => "object",
        "additionalProperties" => false
      )
      expect(definitions.dig("index_definition", "required")).to contain_exactly("index_type", "value")
      expect(definitions.dig("index_definition", "properties", "source", "properties")).to include(
        "ptr" => {
          "type" => "string"
        },
        "each" => {
          "type" => "boolean"
        }
      )
      expect(definitions.dig("index_expression", "properties")).to include(
        "ptr" => {
          "type" => "string"
        },
        "root_ptr" => {
          "type" => "string"
        }
      )
      expect(definitions.dig("index_expression", "properties", "transform", "properties", "strip_prefix")).to eq("type" => "string")
    end
  end
end
