# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DraftsController#patch_ptr", type: :request do
  let(:domain) { create(:domain) }

  let(:schema_body) do
    {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "$id" => "http://journey/event",
      "type" => "object",
      "properties" => {
        "character_class" => {
          "type" => "string",
          "enum" => %w[Warlock Sorceress]
        },
        "character_level" => {
          "type" => "integer"
        },
        "notable" => {
          "type" => "boolean"
        },
        "notes" => {
          "type" => "string"
        },
        "required_name" => {
          "type" => "string"
        },
        "attributes" => {
          "type" => "object",
          "properties" => {
            "hair_color" => { "type" => "string" }
          }
        }
      },
      "required" => [ "required_name" ]
    }
  end

  let(:schema_document) do
    create(:document, :with_head_revision,
      domain:,
      key: "journey-event",
      head_body: schema_body)
  end

  let(:document) do
    create(:document,
      domain:,
      key: "journey-1",
      schema_document:)
  end

  let(:draft) do
    create(:draft,
      document:,
      based_on_revision: document.head_revision,
      body: {})
  end

  it "stores enum values as strings" do
    patch patch_ptr_draft_path(draft, format: :turbo_stream),
      params: { ptr: "/character_class", value: "Warlock" }

    expect(response).to have_http_status(:no_content)
    expect(draft.reload.body).to eq("character_class" => "Warlock")
  end

  it "stores integers as integers" do
    patch patch_ptr_draft_path(draft, format: :turbo_stream),
      params: { ptr: "/character_level", value: "28" }

    expect(response).to have_http_status(:no_content)
    expect(draft.reload.body).to eq("character_level" => 28)
  end

  it "stores booleans as booleans" do
    patch patch_ptr_draft_path(draft, format: :turbo_stream),
      params: { ptr: "/notable", value: "true" }

    expect(response).to have_http_status(:no_content)
    expect(draft.reload.body).to eq("notable" => true)
  end

  it "stores false booleans as false" do
    patch patch_ptr_draft_path(draft, format: :turbo_stream),
      params: { ptr: "/notable", value: "false" }

    expect(response).to have_http_status(:no_content)
    expect(draft.reload.body).to eq("notable" => false)
  end

  it "stores text as text" do
    patch patch_ptr_draft_path(draft, format: :turbo_stream),
      params: { ptr: "/notes", value: "Found Sander's RipRap" }

    expect(response).to have_http_status(:no_content)
    expect(draft.reload.body).to eq("notes" => "Found Sander's RipRap")
  end

  it "does not persist optional blank enum values" do
    patch patch_ptr_draft_path(draft, format: :turbo_stream),
      params: { ptr: "/character_class", value: "" }

    expect(response).to have_http_status(:no_content)
    expect(draft.reload.body).to eq({})
  end

  it "persists required blank values so the key exists" do
    patch patch_ptr_draft_path(draft, format: :turbo_stream),
      params: { ptr: "/required_name", value: "" }

    expect(response).to have_http_status(:no_content)
    expect(draft.reload.body).to eq("required_name" => "")
  end

  it "creates missing parent objects for nested field updates" do
    patch patch_ptr_draft_path(draft, format: :turbo_stream),
      params: { ptr: "/attributes/hair_color", value: "brown" }

    expect(response).to have_http_status(:no_content)
    expect(draft.reload.body).to eq(
      "attributes" => { "hair_color" => "brown" }
    )
  end

  it "creates missing array item parents for indexed nested field updates" do
    patch patch_ptr_draft_path(draft, format: :turbo_stream),
      params: { ptr: "/items/0/name", value: "Ink" }

    expect(response).to have_http_status(:no_content)
    expect(draft.reload.body).to eq(
      "items" => [
        { "name" => "Ink" }
      ]
    )
  end
end
