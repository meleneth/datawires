# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Edit affordance builder", type: :request do
  let(:domain) { create(:domain) }
  let(:schema_document) do
    create(
      :document,
      :with_head_revision,
      domain: domain,
      key: "profile",
      head_body: {
        "$schema" => Document::JSON_SCHEMA_2020_12,
        "$id" => "http://example.test/schemas/profile",
        "type" => "object",
        "properties" => {
          "name" => {
            "type" => "string",
            "title" => "Display Name"
          },
          "bio" => {
            "type" => "string",
            "title" => "Biography"
          },
          "items" => {
            "type" => "array",
            "items" => {
              "type" => "object",
              "properties" => {
                "label" => { "type" => "string" }
              }
            }
          }
        },
        "required" => [ "name" ]
      }
    )
  end
  let!(:schema_wrapper) { create(:schema_wrapper, document: schema_document) }

  it "creates an edit affordance from the schema page and opens the builder draft" do
    get schema_path(schema_wrapper)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("New edit affordance")

    expect {
      post schema_edit_affordances_path(schema_wrapper), params: {
        title: "Builder"
      }
    }.to change(EditAffordance, :count).by(1)
      .and change(Document, :count).by(1)
      .and change(Draft, :count).by(1)

    edit_affordance = EditAffordance.order(:created_at).last
    draft = edit_affordance.edit_document.drafts.sole

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft))
    expect(draft.body.fetch("screens").first.fetch("id")).to eq("main")
    expect(draft.body.fetch("screens").first).to include(
      "default_span" => 3,
      "width" => "large"
    )
  end

  it "adds fields to selected rows through the constrained builder and previews the seeded projection" do
    draft = create_builder_draft

    get draft_edit_affordance_builder_path(draft)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Builder")
    expect(response.body).to include("Preview")
    expect(response.body).to include("Diagnostics")
    expect(response.body).to include("Raw")
    expect(response.body).to include("max-width: 1920px;")
    expect(response.body).to include("Display Name (/name)")
    expect(response.body).to include("Biography (/bio)")
    expect(response.body).to include("Screen layout")
    expect(response.body).to include("Add row")
    expect(response.body).to include("Collection policy: array fields only.")

    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/name",
      widget: "text",
      row_index: "new",
      label: "1",
      help: "Use the public name."
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    cell = draft.reload.body.fetch("screens").first.fetch("rows").first.first
    expect(cell).to include(
      "binding" => {
        "kind" => "document_ptr",
        "ptr" => "/name"
      },
      "widget" => "text",
      "span" => 3,
      "help" => "Use the public name."
    )
    expect(cell).not_to have_key("collection")

    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/bio",
      widget: "textarea",
      row_index: "0",
      span: "12",
      label: "1",
      help: "Longer author-facing copy."
    }

    rows = draft.reload.body.fetch("screens").first.fetch("rows")
    expect(rows.length).to eq(1)
    expect(rows.first.map { |field| field.dig("binding", "ptr") }).to eq(%w[/name /bio])

    get draft_edit_affordance_builder_path(draft, tab: "preview")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Seeded preview")
    expect(response.body).to include("Display Name")
    expect(response.body).to include("/name")
  end

  it "adds explicit empty rows and shows row diagnostics until filled" do
    draft = create_builder_draft

    patch add_row_draft_edit_affordance_builder_path(draft)

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    expect(draft.reload.body.dig("screens", 0, "rows")).to eq([ [] ])

    get draft_edit_affordance_builder_path(draft, tab: "diagnostics")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("screens/0/rows/0 must contain at least one cell")
  end

  it "visits row and field nodes, reorders fields, and deletes created nodes" do
    draft = create_builder_draft

    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/name",
      widget: "text",
      row_index: "new",
      label: "1"
    }
    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/bio",
      widget: "textarea",
      row_index: "0",
      label: "1"
    }

    get draft_edit_affordance_builder_path(draft)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(row_draft_edit_affordance_builder_path(draft, row_index: 0))
    expect(response.body).to include(cell_draft_edit_affordance_builder_path(draft, row_index: 0, cell_index: 0))

    get row_draft_edit_affordance_builder_path(draft, row_index: 0)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Row 1")
    expect(response.body).to include("Left")
    expect(response.body).to include("Right")
    expect(response.body).to include("Delete row")

    patch move_cell_draft_edit_affordance_builder_path(draft, row_index: 0, cell_index: 0), params: {
      direction: "right"
    }

    expect(response).to redirect_to(row_draft_edit_affordance_builder_path(draft, row_index: 0))
    expect(draft.reload.body.dig("screens", 0, "rows", 0).map { |cell| cell.dig("binding", "ptr") }).to eq(%w[/bio /name])

    get cell_draft_edit_affordance_builder_path(draft, row_index: 0, cell_index: 1)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Field 2")
    expect(response.body).to include("/name")
    expect(response.body).to include("Delete field")

    delete cell_draft_edit_affordance_builder_path(draft, row_index: 0, cell_index: 1)

    expect(response).to redirect_to(row_draft_edit_affordance_builder_path(draft, row_index: 0))
    expect(draft.reload.body.dig("screens", 0, "rows", 0).map { |cell| cell.dig("binding", "ptr") }).to eq(%w[/bio])

    delete row_draft_edit_affordance_builder_path(draft, row_index: 0)

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    expect(draft.reload.body.dig("screens", 0, "rows")).to eq([])
  end

  it "reorders rows from the main builder screen" do
    draft = create_builder_draft

    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/name",
      widget: "text",
      row_index: "new",
      label: "1"
    }
    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/bio",
      widget: "textarea",
      row_index: "new",
      label: "1"
    }

    get draft_edit_affordance_builder_path(draft)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Up")
    expect(response.body).to include("Down")
    expect(response.body).to include(move_row_draft_edit_affordance_builder_path(draft, row_index: 1))

    patch move_row_draft_edit_affordance_builder_path(draft, row_index: 1), params: {
      direction: "up"
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    expect(draft.reload.body.dig("screens", 0, "rows").map { |row| row.first.dig("binding", "ptr") }).to eq(%w[/bio /name])

    patch move_row_draft_edit_affordance_builder_path(draft, row_index: 0), params: {
      direction: "down"
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    expect(draft.reload.body.dig("screens", 0, "rows").map { |row| row.first.dig("binding", "ptr") }).to eq(%w[/name /bio])
  end

  it "updates screen width and default span" do
    draft = create_builder_draft

    patch update_screen_draft_edit_affordance_builder_path(draft), params: {
      width: "full",
      default_span: "5"
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    expect(draft.reload.body.fetch("screens").first).to include(
      "width" => "full",
      "default_span" => 5
    )

    get draft_edit_affordance_builder_path(draft, tab: "preview")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("w-full")
  end

  it "configures collection policy and item bindings for array fields" do
    draft = create_builder_draft

    get draft_edit_affordance_builder_path(draft)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Collection options")
    expect(response.body).to include("Item screen")
    expect(response.body).to include("Title binding")
    expect(response.body).to include("data-array=\"true\"")

    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/items",
      widget: "array",
      span: "12",
      row_index: "new",
      label: "1",
      collection_presentation: "cards",
      collection_creation: "inline_blank_form",
      collection_delete: "enabled",
      collection_reorder: "enabled",
      collection_item_screen: "item",
      item_title_kind: "property",
      item_title_name: "label",
      item_subtitle_kind: "value_label"
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    collection = draft.reload.body.dig("screens", 0, "rows", 0, 0, "collection")

    expect(collection).to include(
      "behavior" => "list_open",
      "presentation" => "cards",
      "creation" => "inline_blank_form",
      "navigation" => "open_item",
      "delete" => "enabled",
      "reorder" => "enabled",
      "item_screen" => "item",
      "item_title" => {
        "kind" => "property",
        "name" => "label"
      },
      "item_subtitle" => {
        "kind" => "value_label"
      }
    )

    get draft_edit_affordance_builder_path(draft, tab: "diagnostics")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("item_screen must match a screen id")
  end

  it "updates raw JSON and reports diagnostics" do
    draft = create_builder_draft

    patch update_raw_draft_edit_affordance_builder_path(draft), params: {
      body_json: JSON.pretty_generate(
        "version" => 1,
        "screens" => [
          {
            "id" => "main",
            "rows" => [
              [
                {
                  "kind" => "unknown"
                }
              ]
            ]
          }
        ]
      )
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "raw"))
    expect(draft.reload.body.dig("screens", 0, "rows", 0, 0, "kind")).to eq("unknown")

    get draft_edit_affordance_builder_path(draft, tab: "diagnostics")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("must be a field, navigation, or commit cell")

    patch update_raw_draft_edit_affordance_builder_path(draft), params: {
      body_json: "{"
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "raw"))
    follow_redirect!
    expect(response.body).to include("Invalid JSON")
  end

  def create_builder_draft
    CreateEditAffordance.call(
      schema_wrapper: schema_wrapper,
      title: "Builder",
      actor: User.find_or_create_by!(id: ApplicationController::DEV_USER_ID) do |user|
        user.name = "devUser"
      end
    ).draft
  end
end
