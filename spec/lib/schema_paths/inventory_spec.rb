# frozen_string_literal: true

require "rails_helper"

RSpec.describe SchemaPaths::Inventory do
  let(:schema_body) do
    {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "$id" => "http://example.test/schemas/inventory",
      "type" => "object",
      "properties" => {
        "name" => {
          "type" => "string",
          "title" => "Display Name"
        },
        "active" => {
          "type" => "boolean"
        },
        "items" => {
          "type" => "array",
          "items" => {
            "type" => "object",
            "properties" => {
              "label" => { "type" => "string" }
            }
          }
        },
        "metadata" => {
          "type" => "object",
          "properties" => {
            "notes" => { "type" => "string" }
          },
          "required" => [ "notes" ]
        }
      },
      "required" => [ "name" ]
    }
  end

  let(:schema_document) do
    create(:document, :with_head_revision, head_body: schema_body)
  end

  let(:draft) do
    build(
      :draft,
      document: build(:document, schema_document: schema_document),
      body: {}
    )
  end

  let(:root_cursor) { Documents::Cursor.new(source: draft, path: "") }

  it "lists direct schema paths with labels, kinds, widgets, and required flags" do
    entries = described_class.new(root_cursor: root_cursor).root_entries

    expect(entries.map(&:name)).to eq(%w[active items metadata name])
    expect(entries.map(&:ptr).map(&:to_s)).to eq(%w[/active /items /metadata /name])
    expect(entries.map(&:kind)).to eq(%w[scalar array object scalar])
    expect(entries.map(&:widget)).to eq(%w[checkbox array text text])
    expect(entries.map(&:label)).to eq([ "Active", "Items", "Metadata", "Display Name" ])
    expect(entries.map(&:required?)).to eq([ false, false, false, true ])
  end

  it "lists child schema paths for object entries" do
    inventory = described_class.new(root_cursor: root_cursor)
    metadata_entry = inventory.root_entries.detect { |entry| entry.name == "metadata" }

    child_entries = inventory.entries_for(metadata_entry.cursor)

    expect(child_entries.map(&:name)).to eq([ "notes" ])
    expect(child_entries.first.ptr.to_s).to eq("/metadata/notes")
    expect(child_entries.first).to be_required
  end
end
