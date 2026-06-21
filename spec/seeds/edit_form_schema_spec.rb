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
    end
  end
end
