# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Draft array items", type: :request do
  let(:domain) { create(:domain) }

  let(:schema_body) do
    {
      "$schema" => Document::JSON_SCHEMA_2020_12,
      "$id" => "http://example.test/schemas/list",
      "type" => "object",
      "properties" => {
        "items" => {
          "type" => "array",
          "items" => {
            "type" => "object",
            "properties" => {
              "name" => { "type" => "string" },
              "quantity" => { "type" => "integer" }
            },
            "required" => [ "name" ]
          }
        }
      }
    }
  end

  let(:schema_document) do
    create(
      :document,
      :with_head_revision,
      domain: domain,
      key: "list",
      head_body: schema_body
    )
  end

  let!(:schema_wrapper) { create(:schema_wrapper, document: schema_document) }

  let(:document) do
    create(
      :document,
      domain: domain,
      schema_document: schema_document
    )
  end

  let(:draft) { create(:draft, document: document, body: {}) }

  it "shows a dangerous abandon button on the draft editor" do
    get draft_path(draft)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Abandon")
    expect(response.body).to include(%(action="#{draft_path(draft)}"))
  end

  it "redirects to the new object item screen after adding an item" do
    patch add_item_draft_path(draft), params: {
      ptr: "/items"
    }

    expect(response).to redirect_to(draft_path(draft, path: "/items/0"))
    expect(draft.reload.body).to eq(
      "items" => [
        { "name" => nil }
      ]
    )
  end

  it "renders the new object item editor after adding an item over turbo stream" do
    patch add_item_draft_path(draft, format: :turbo_stream), params: {
      ptr: "/items"
    }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(target="editor"))
    expect(response.body).to include("Name")
    expect(response.body).to include("Quantity")
    expect(response.body).not_to include("Item 1")
  end

  it "renders existing object items as openable rows instead of inline fields" do
    draft.update!(
      body: {
        "items" => [
          { "name" => "First", "quantity" => 2 }
        ]
      }
    )

    get draft_path(draft)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("1 item")
    expect(response.body).to include("First")
    expect(response.body).to include("Open")
    expect(response.body).not_to include("Quantity")
  end

  it "renders bespoke collection item title and subtitle bindings" do
    draft.update!(
      body: {
        "items" => [
          { "name" => "Ink", "quantity" => 2 }
        ]
      }
    )
    edit_document = create(
      :document,
      :with_head_revision,
      domain: domain,
      head_body: {
        "version" => 1,
        "rows" => [
          [
            {
              "binding" => {
                "kind" => "document_ptr",
                "ptr" => "/items"
              },
              "widget" => "array",
              "collection" => {
                "behavior" => "list_open",
                "presentation" => "list",
                "creation" => "new_screen",
                "navigation" => "open_item",
                "delete" => "disabled",
                "reorder" => "disabled",
                "item_title" => {
                  "kind" => "property",
                  "name" => "name"
                },
                "item_subtitle" => {
                  "kind" => "property",
                  "name" => "quantity"
                }
              }
            }
          ]
        ]
      }
    )
    edit_affordance = build(
      :edit_affordance,
      schema_wrapper: schema_wrapper,
      edit_document: edit_document
    )
    edit_affordance.save!(validate: false)

    get draft_path(draft, edit_affordance_id: edit_affordance.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ink")
    expect(response.body).to include("2")
    expect(response.body).to include("Open")
  end

  it "renders collection table presentation" do
    draft.update!(
      body: {
        "items" => [
          { "name" => "Ink", "quantity" => 2 }
        ]
      }
    )
    edit_affordance = create_collection_affordance(presentation: "table")

    get draft_path(draft, edit_affordance_id: edit_affordance.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<table")
    expect(response.body).to include("<th")
    expect(response.body).to include("Ink")
    expect(response.body).to include("Open")
  end

  it "submits collection creation and navigation policy when adding an item" do
    edit_affordance = create_collection_affordance(presentation: "list")

    get draft_path(draft, edit_affordance_id: edit_affordance.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('name="collection_creation"')
    expect(response.body).to include('value="new_screen"')
    expect(response.body).to include('name="collection_navigation"')
    expect(response.body).to include('value="open_item"')
  end

  it "renders collection cards presentation" do
    draft.update!(
      body: {
        "items" => [
          { "name" => "Ink", "quantity" => 2 }
        ]
      }
    )
    edit_affordance = create_collection_affordance(presentation: "cards")

    get draft_path(draft, edit_affordance_id: edit_affordance.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("md:grid-cols-2")
    expect(response.body).to include("Ink")
    expect(response.body).to include("Open")
  end

  it "renders inline blank form creation for the next array item" do
    edit_affordance = create_collection_affordance(
      presentation: "list",
      creation: "inline_blank_form"
    )

    get draft_path(draft, edit_affordance_id: edit_affordance.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("New item")
    expect(response.body).to include('value="/items/0/name"')
    expect(response.body).to include('value="/items/0/quantity"')
    expect(response.body).not_to include("Add item")
  end

  def create_collection_affordance(presentation:, creation: "new_screen")
    edit_document = create(
      :document,
      :with_head_revision,
      domain: domain,
      head_body: {
        "version" => 1,
        "rows" => [
          [
            {
              "binding" => {
                "kind" => "document_ptr",
                "ptr" => "/items"
              },
              "widget" => "array",
              "collection" => {
                "behavior" => "list_open",
                "presentation" => presentation,
                "creation" => creation,
                "navigation" => "open_item",
                "delete" => "disabled",
                "reorder" => "disabled",
                "item_title" => {
                  "kind" => "property",
                  "name" => "name"
                },
                "item_subtitle" => {
                  "kind" => "property",
                  "name" => "quantity"
                }
              }
            }
          ]
        ]
      }
    )
    edit_affordance = build(
      :edit_affordance,
      schema_wrapper: schema_wrapper,
      edit_document: edit_document
    )
    edit_affordance.save!(validate: false)
    edit_affordance
  end
end
