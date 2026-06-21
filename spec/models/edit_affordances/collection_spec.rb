# frozen_string_literal: true

require "rails_helper"

RSpec.describe EditAffordances::Collection do
  describe ".default" do
    it "models the current list-open collection behavior" do
      collection = described_class.default

      expect(collection.behavior).to eq("list_open")
      expect(collection.presentation).to eq("list")
      expect(collection.creation).to eq("new_screen")
      expect(collection.navigation).to eq("open_item")
      expect(collection.delete_policy).to eq("disabled")
      expect(collection.reorder_policy).to eq("disabled")
    end
  end

  describe "#creation" do
    it "normalizes the old append_and_open creation name to new_screen" do
      collection = described_class.new(
        "creation" => "append_and_open"
      )

      expect(collection.creation).to eq("new_screen")
    end

    it "identifies inline blank form creation" do
      collection = described_class.new(
        "creation" => "inline_blank_form"
      )

      expect(collection).to be_inline_blank_form
    end
  end

  describe "#item_title_for" do
    it "defaults to a name property and falls back when it is blank" do
      schema_document = build(:document, :with_name_schema)
      document = build(:document, schema_document: schema_document)
      draft = build(:draft, document: document, body: { "items" => [ { "name" => "First" }, {} ] })
      named_cursor = Documents::Cursor.new(source: draft, path: "/items/0")
      unnamed_cursor = Documents::Cursor.new(source: draft, path: "/items/1")

      collection = described_class.default

      expect(collection.item_title_for(named_cursor, fallback: "Item 1")).to eq("First")
      expect(collection.item_title_for(unnamed_cursor, fallback: "Item 2")).to eq("Item 2")
    end
  end
end
