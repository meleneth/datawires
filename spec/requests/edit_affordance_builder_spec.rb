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
          },
          "thumbnail" => {
            "type" => "string",
            "title" => "Thumbnail"
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
    expect(response.body).to include("base64_image")
    expect(response.body).to include("Reference options")
    expect(response.body).to include("Screen layout")
    expect(response.body).to include("Add row")
    expect(response.body).to include("Add a row before adding fields.")
    expect(response.body).to include("Collection policy: array fields only.")

    patch add_row_draft_edit_affordance_builder_path(draft)

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))

    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/name",
      widget: "text",
      row_index: "0",
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

  it "requires an existing row before adding a field" do
    draft = create_builder_draft

    expect {
      patch add_field_draft_edit_affordance_builder_path(draft), params: {
        ptr: "/name",
        widget: "text",
        row_index: "new",
        label: "1"
      }
    }.not_to change { draft.reload.body.dig("screens", 0, "rows") }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    follow_redirect!
    expect(response.body).to include("Add a row before adding fields.")
  end

  it "continues an uncommitted edit affordance draft from the schema page" do
    draft = create_builder_draft
    edit_affordance = draft.document.edit_affordance

    get schema_path(schema_wrapper)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Continue editing")
    expect(response.body).to include(draft_schema_edit_affordance_path(schema_wrapper, edit_affordance))

    expect {
      post draft_schema_edit_affordance_path(schema_wrapper, edit_affordance)
    }.not_to change(Draft, :count)

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft))
  end

  it "opens a new builder draft for an existing committed edit affordance" do
    original_draft = create_builder_draft
    edit_affordance = original_draft.document.edit_affordance
    original_draft.destroy!

    get schema_path(schema_wrapper)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Edit affordance")

    expect {
      post draft_schema_edit_affordance_path(schema_wrapper, edit_affordance)
    }.to change(Draft, :count).by(1)

    draft = Draft.order(:created_at).last
    expect(draft.document).to eq(edit_affordance.edit_document)
    expect(draft.based_on_revision).to eq(edit_affordance.edit_document.head_revision)
    expect(draft.body).to eq(edit_affordance.edit_document.body)
    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft))
  end

  it "deletes an edit affordance and its backing draft document from the builder" do
    draft = create_builder_draft
    edit_document = draft.document
    edit_affordance = edit_document.edit_affordance
    revision = edit_document.head_revision

    get draft_edit_affordance_builder_path(draft)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Delete affordance")
    expect(response.body).to include(affordance_draft_edit_affordance_builder_path(draft))

    expect {
      delete affordance_draft_edit_affordance_builder_path(draft)
    }.to change(EditAffordance, :count).by(-1)
      .and change(Draft, :count).by(-1)
      .and change(Document, :count).by(-1)
      .and change(Revision, :count).by(-1)

    expect(EditAffordance.exists?(edit_affordance.id)).to be(false)
    expect(Draft.exists?(draft.id)).to be(false)
    expect(Document.exists?(edit_document.id)).to be(false)
    expect(Revision.exists?(revision.id)).to be(false)
    expect(response).to redirect_to(schema_path(schema_wrapper))
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

    patch add_row_draft_edit_affordance_builder_path(draft)
    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/name",
      widget: "text",
      row_index: "0",
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

    patch add_row_draft_edit_affordance_builder_path(draft)
    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/name",
      widget: "text",
      row_index: "0",
      label: "1"
    }
    patch add_row_draft_edit_affordance_builder_path(draft)
    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/bio",
      widget: "textarea",
      row_index: "1",
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
    expect(response.body).to include("Add navigation")
    expect(response.body).to include("Add commit")

    patch add_row_draft_edit_affordance_builder_path(draft)
    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/items",
      widget: "array",
      span: "12",
      row_index: "0",
      label: "1",
      collection_presentation: "cards",
      collection_creation: "inline_blank_form",
      collection_delete: "enabled",
      collection_reorder: "enabled",
      collection_item_screen: "main",
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
      "item_screen" => "main",
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
    expect(response.body).to include("No diagnostics.")
  end

  it "rejects collection item screens that do not exist" do
    draft = create_builder_draft

    patch add_row_draft_edit_affordance_builder_path(draft)

    expect {
      patch add_field_draft_edit_affordance_builder_path(draft), params: {
        ptr: "/items",
        widget: "array",
        row_index: "0",
        label: "1",
        collection_item_screen: "missing"
      }
    }.not_to change { draft.reload.body.dig("screens", 0, "rows", 0) }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    follow_redirect!
    expect(response.body).to include("Select an existing screen.")
  end

  it "updates existing field cells through structured controls" do
    draft = create_builder_draft

    patch add_row_draft_edit_affordance_builder_path(draft)
    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/name",
      widget: "text",
      row_index: "0",
      label: "1"
    }

    get cell_draft_edit_affordance_builder_path(draft, row_index: 0, cell_index: 0)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Update field")
    expect(response.body).to include("Placeholder")

    patch cell_draft_edit_affordance_builder_path(draft, row_index: 0, cell_index: 0), params: {
      ptr: "/bio",
      widget: "textarea",
      span: "8",
      help: "Revised help.",
      placeholder: "Long form copy"
    }

    expect(response).to redirect_to(cell_draft_edit_affordance_builder_path(draft, row_index: 0, cell_index: 0))
    cell = draft.reload.body.dig("screens", 0, "rows", 0, 0)
    expect(cell).to include(
      "binding" => {
        "kind" => "document_ptr",
        "ptr" => "/bio"
      },
      "widget" => "textarea",
      "span" => 8,
      "label" => false,
      "help" => "Revised help.",
      "placeholder" => "Long form copy"
    )
  end

  it "adds base64 image fields through the structured builder" do
    draft = create_builder_draft

    patch add_row_draft_edit_affordance_builder_path(draft)
    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/thumbnail",
      widget: "base64_image",
      row_index: "0",
      label: "1"
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    expect(draft.reload.body.dig("screens", 0, "rows", 0, 0)).to include(
      "binding" => {
        "kind" => "document_ptr",
        "ptr" => "/thumbnail"
      },
      "widget" => "base64_image"
    )
  end

  it "adds reference fields through the structured builder" do
    draft = create_builder_draft

    patch add_row_draft_edit_affordance_builder_path(draft)
    patch add_field_draft_edit_affordance_builder_path(draft), params: {
      ptr: "/name",
      widget: "reference",
      row_index: "0",
      label: "1",
      reference_schema_key: "person",
      reference_index_type: "identity",
      reference_placeholder: "Select person"
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    expect(draft.reload.body.dig("screens", 0, "rows", 0, 0)).to include(
      "widget" => "reference",
      "reference" => {
        "schema_key" => "person",
        "index_type" => "identity",
        "placeholder" => "Select person"
      }
    )
  end

  it "adds and updates navigation and commit cells" do
    draft = create_builder_draft

    patch update_raw_draft_edit_affordance_builder_path(draft), params: {
      body_json: JSON.pretty_generate(
        draft.body.merge(
          "screens" => [
            draft.body.fetch("screens").first,
            {
              "id" => "details",
              "title" => "Details",
              "columns" => 12,
              "default_span" => 3,
              "rows" => []
            }
          ]
        )
      )
    }
    patch add_row_draft_edit_affordance_builder_path(draft)

    patch add_navigation_draft_edit_affordance_builder_path(draft), params: {
      row_index: "0",
      target_screen: "details",
      navigation_label: "Open details",
      navigation_span: "4"
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    expect(draft.reload.body.dig("screens", 0, "rows", 0, 0)).to include(
      "kind" => "navigation",
      "target_screen" => "details",
      "label" => "Open details",
      "span" => 4
    )

    patch add_commit_draft_edit_affordance_builder_path(draft), params: {
      row_index: "0",
      commit_span: "8",
      commit_mode: "immediate",
      message_mode: "inline_required"
    }

    expect(draft.reload.body.dig("screens", 0, "rows", 0, 1)).to include(
      "kind" => "commit",
      "span" => 8,
      "commit_mode" => "immediate",
      "message_mode" => "inline_required"
    )

    get cell_draft_edit_affordance_builder_path(draft, row_index: 0, cell_index: 0)
    expect(response.body).to include("Update navigation")

    patch cell_draft_edit_affordance_builder_path(draft, row_index: 0, cell_index: 0), params: {
      target_screen: "main",
      navigation_label: "Back",
      navigation_span: "6"
    }

    expect(draft.reload.body.dig("screens", 0, "rows", 0, 0)).to include(
      "target_screen" => "main",
      "label" => "Back",
      "span" => 6
    )

    get cell_draft_edit_affordance_builder_path(draft, row_index: 0, cell_index: 1)
    expect(response.body).to include("Update commit")

    patch cell_draft_edit_affordance_builder_path(draft, row_index: 0, cell_index: 1), params: {
      commit_span: "12",
      commit_mode: "review_screen",
      message_mode: "hidden"
    }

    expect(draft.reload.body.dig("screens", 0, "rows", 0, 1)).to include(
      "span" => 12,
      "commit_mode" => "review_screen",
      "message_mode" => "hidden"
    )
  end

  it "adds screens and edits rows on the selected screen" do
    draft = create_builder_draft

    get draft_edit_affordance_builder_path(draft)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Add screen")
    expect(response.body).to include("Add subform")

    patch add_screen_draft_edit_affordance_builder_path(draft), params: {
      new_screen_id: "details",
      new_screen_title: "Details",
      new_screen_root_ptr: "/profile",
      new_screen_width: "medium",
      new_screen_default_span: "6"
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder", screen_id: "details"))
    details = draft.reload.body.fetch("screens").second
    expect(details).to include(
      "id" => "details",
      "title" => "Details",
      "width" => "medium",
      "default_span" => 6,
      "root_binding" => {
        "kind" => "document_ptr",
        "ptr" => "/profile"
      },
      "rows" => []
    )

    patch add_row_draft_edit_affordance_builder_path(draft, screen_id: "details")
    patch add_field_draft_edit_affordance_builder_path(draft, screen_id: "details"), params: {
      ptr: "/bio",
      widget: "textarea",
      row_index: "0",
      label: "1"
    }

    expect(draft.reload.body.dig("screens", 1, "rows", 0, 0)).to include(
      "binding" => {
        "kind" => "document_ptr",
        "ptr" => "/bio"
      },
      "widget" => "textarea"
    )

    get draft_edit_affordance_builder_path(draft, tab: "builder", screen_id: "details")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("details")
    expect(response.body).to include("Biography")
  end

  it "adds subforms and edits subform rows through screens that reference them" do
    draft = create_builder_draft

    patch add_subform_draft_edit_affordance_builder_path(draft), params: {
      new_subform_id: "profile_fields",
      new_subform_root_ptr: "/profile"
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    expect(draft.reload.body.fetch("subforms").first).to include(
      "id" => "profile_fields",
      "root_binding" => {
        "kind" => "document_ptr",
        "ptr" => "/profile"
      },
      "rows" => []
    )

    patch add_screen_draft_edit_affordance_builder_path(draft), params: {
      new_screen_id: "profile",
      new_screen_title: "Profile",
      new_screen_root_ptr: "/profile",
      new_screen_subform: "profile_fields"
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder", screen_id: "profile"))
    expect(draft.reload.body.fetch("screens").second).to include(
      "id" => "profile",
      "subform" => "profile_fields"
    )
    expect(draft.reload.body.fetch("screens").second).not_to have_key("rows")

    patch add_row_draft_edit_affordance_builder_path(draft, screen_id: "profile")
    patch add_field_draft_edit_affordance_builder_path(draft, screen_id: "profile"), params: {
      ptr: "/name",
      widget: "text",
      row_index: "0",
      label: "1"
    }

    expect(draft.reload.body.dig("subforms", 0, "rows", 0, 0)).to include(
      "binding" => {
        "kind" => "document_ptr",
        "ptr" => "/name"
      },
      "widget" => "text"
    )

    get draft_edit_affordance_builder_path(draft, tab: "builder", screen_id: "profile")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Rows edit subform profile_fields.")
  end

  it "rejects duplicate screen and subform identifiers" do
    draft = create_builder_draft

    patch add_screen_draft_edit_affordance_builder_path(draft), params: {
      new_screen_id: "main"
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    follow_redirect!
    expect(response.body).to include("Screen id already exists.")

    patch add_subform_draft_edit_affordance_builder_path(draft), params: {
      new_subform_id: "profile_fields"
    }
    patch add_subform_draft_edit_affordance_builder_path(draft), params: {
      new_subform_id: "profile_fields"
    }

    expect(response).to redirect_to(draft_edit_affordance_builder_path(draft, tab: "builder"))
    follow_redirect!
    expect(response.body).to include("Subform id already exists.")
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
