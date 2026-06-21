# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bespoke draft affordances", type: :request do
  def parsed_body
    Nokogiri::HTML(response.body)
  end

  it "renders textarea widgets as textareas" do
    schema_wrapper = create(
      :schema_wrapper,
      document: create(
        :document,
        :with_head_revision,
        head_body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "http://example.test/schemas/note",
          "type" => "object",
          "properties" => {
            "notes" => { "type" => "string" }
          }
        }
      )
    )
    document = create(
      :document,
      domain: schema_wrapper.domain,
      schema_document: schema_wrapper.document
    )
    draft = create(:draft, document:, body: { "notes" => "Already here" })
    edit_document = create(
      :document,
      :with_head_revision,
      domain: schema_wrapper.domain,
      head_body: {
        "version" => 1,
        "screen" => {
          "mode" => "page",
          "columns" => 6,
          "default_span" => 6,
          "commit_mode" => "review_screen"
        },
        "rows" => [
          [
            {
              "binding" => {
                "kind" => "document_ptr",
                "ptr" => "/notes"
              },
              "span" => 6,
              "widget" => "textarea"
            }
          ]
        ]
      }
    )
    edit_affordance = build(
      :edit_affordance,
      schema_wrapper:,
      edit_document:
    )
    edit_affordance.save!(validate: false)

    get draft_path(draft, edit_affordance_id: edit_affordance.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<textarea")
    expect(response.body).to include("Already here")
  end

  it "renders field help, placeholders, and required markers" do
    schema_wrapper = create(
      :schema_wrapper,
      document: create(:document, :with_name_schema)
    )
    document = create(
      :document,
      domain: schema_wrapper.domain,
      schema_document: schema_wrapper.document
    )
    draft = create(:draft, document:, body: {})
    edit_document = create(
      :document,
      :with_head_revision,
      domain: schema_wrapper.domain,
      head_body: {
        "version" => 1,
        "screen" => {
          "mode" => "page",
          "columns" => 6,
          "default_span" => 6,
          "commit_mode" => "review_screen"
        },
        "rows" => [
          [
            {
              "binding" => {
                "kind" => "document_ptr",
                "ptr" => "/name"
              },
              "widget" => "text",
              "help" => "Use the public display name.",
              "placeholder" => "Ada Lovelace"
            }
          ]
        ]
      }
    )
    edit_affordance = build(
      :edit_affordance,
      schema_wrapper:,
      edit_document:
    )
    edit_affordance.save!(validate: false)

    get draft_path(draft, edit_affordance_id: edit_affordance.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Use the public display name.")
    expect(response.body).to include('placeholder="Ada Lovelace"')
    expect(response.body).to include(">*</span>")
  end

  it "uses schema inventory metadata for bespoke field defaults" do
    schema_wrapper = create(
      :schema_wrapper,
      document: create(
        :document,
        :with_head_revision,
        head_body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "http://example.test/schemas/person",
          "type" => "object",
          "properties" => {
            "name" => {
              "type" => "string",
              "title" => "Display Name"
            }
          },
          "required" => [ "name" ]
        }
      )
    )
    document = create(
      :document,
      domain: schema_wrapper.domain,
      schema_document: schema_wrapper.document
    )
    draft = create(:draft, document:, body: {})
    edit_document = create(
      :document,
      :with_head_revision,
      domain: schema_wrapper.domain,
      head_body: {
        "version" => 1,
        "rows" => [
          [
            {
              "binding" => {
                "kind" => "document_ptr",
                "ptr" => "/name"
              }
            }
          ]
        ]
      }
    )
    edit_affordance = build(
      :edit_affordance,
      schema_wrapper:,
      edit_document:
    )
    edit_affordance.save!(validate: false)

    get draft_path(draft, edit_affordance_id: edit_affordance.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Display Name")
    expect(response.body).to include(">*</span>")
  end

  it "renders field display options and autosave actions for supported widgets" do
    schema_wrapper = create(
      :schema_wrapper,
      document: create(
        :document,
        :with_head_revision,
        head_body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "http://example.test/schemas/character",
          "type" => "object",
          "properties" => {
            "name" => { "type" => "string" },
            "biography" => { "type" => "string" },
            "level" => { "type" => "integer" },
            "role" => { "type" => "string", "enum" => %w[Mage Ranger] },
            "active" => { "type" => "boolean" },
            "display_name" => { "type" => "string" }
          },
          "required" => [ "name" ]
        }
      )
    )
    document = create(
      :document,
      domain: schema_wrapper.domain,
      schema_document: schema_wrapper.document
    )
    draft = create(
      :draft,
      document:,
      body: {
        "name" => "",
        "display_name" => "Ada Lovelace"
      }
    )
    edit_document = create(
      :document,
      :with_head_revision,
      domain: schema_wrapper.domain,
      head_body: {
        "version" => 1,
        "screen" => {
          "mode" => "page",
          "columns" => 12,
          "default_span" => 6,
          "commit_mode" => "review_screen"
        },
        "rows" => [
          [
            {
              "binding" => { "kind" => "document_ptr", "ptr" => "/name" },
              "widget" => "text",
              "placeholder" => "Required name",
              "display" => { "compact" => true }
            },
            {
              "binding" => { "kind" => "document_ptr", "ptr" => "/biography" },
              "widget" => "textarea",
              "label" => false
            }
          ],
          [
            {
              "binding" => { "kind" => "document_ptr", "ptr" => "/level" },
              "widget" => "number"
            },
            {
              "binding" => { "kind" => "document_ptr", "ptr" => "/role" },
              "widget" => "select"
            }
          ],
          [
            {
              "binding" => { "kind" => "document_ptr", "ptr" => "/active" },
              "widget" => "checkbox"
            },
            {
              "binding" => { "kind" => "document_ptr", "ptr" => "/display_name" },
              "widget" => "text",
              "display" => { "readonly" => true }
            }
          ]
        ]
      }
    )
    edit_affordance = build(
      :edit_affordance,
      schema_wrapper:,
      edit_document:
    )
    edit_affordance.save!(validate: false)

    get draft_path(draft, edit_affordance_id: edit_affordance.id)

    html = parsed_body
    text_input = html.at_css("input#field_name")
    textarea = html.at_css("textarea#field_biography")
    number = html.at_css("input#field_level")
    select = html.at_css("select#field_role")
    checkbox = html.at_css("input#field_active[type='checkbox']")
    readonly_preview = html.at_css("#field_display_name")

    expect(response).to have_http_status(:ok)
    expect(text_input["class"]).to include("h-8")
    expect(text_input["placeholder"]).to eq("Required name")
    expect(text_input["value"]).to eq("")
    expect(text_input["data-action"]).to eq("input->autosave#queue change->autosave#submit")
    expect(textarea["data-action"]).to eq("input->autosave#queue change->autosave#submit")
    expect(number["data-action"]).to eq("input->autosave#queue change->autosave#submit")
    expect(select["data-action"]).to eq("change->autosave#submit")
    expect(checkbox["data-action"]).to eq("change->autosave#submit")
    expect(readonly_preview.text).to include("Ada Lovelace")
    expect(response.body).not_to include(">Biography</label>")
    expect(response.body).to include("Last saved")
  end

  it "renders optional blank fields as missing and required blank fields as present blanks" do
    schema_wrapper = create(
      :schema_wrapper,
      document: create(
        :document,
        :with_head_revision,
        head_body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "http://example.test/schemas/blank-fields",
          "type" => "object",
          "properties" => {
            "required_name" => { "type" => "string" },
            "optional_name" => { "type" => "string" }
          },
          "required" => [ "required_name" ]
        }
      )
    )
    document = create(
      :document,
      domain: schema_wrapper.domain,
      schema_document: schema_wrapper.document
    )
    draft = create(
      :draft,
      document:,
      body: {
        "required_name" => "",
        "optional_name" => ""
      }
    )

    patch patch_ptr_draft_path(draft, format: :turbo_stream),
      params: { ptr: "/optional_name", value: "" }
    patch patch_ptr_draft_path(draft, format: :turbo_stream),
      params: { ptr: "/required_name", value: "" }

    edit_document = create(
      :document,
      :with_head_revision,
      domain: schema_wrapper.domain,
      head_body: {
        "version" => 1,
        "rows" => [
          [
            {
              "binding" => { "kind" => "document_ptr", "ptr" => "/required_name" },
              "widget" => "text"
            },
            {
              "binding" => { "kind" => "document_ptr", "ptr" => "/optional_name" },
              "widget" => "text"
            }
          ]
        ]
      }
    )
    edit_affordance = build(
      :edit_affordance,
      schema_wrapper:,
      edit_document:
    )
    edit_affordance.save!(validate: false)

    get draft_path(draft.reload, edit_affordance_id: edit_affordance.id)

    html = parsed_body

    expect(draft.body).to eq("required_name" => "")
    expect(response).to have_http_status(:ok)
    expect(html.at_css("input#field_required_name")["value"]).to eq("")
    expect(html.at_css("input#field_optional_name")["value"]).to be_nil
    expect(response.body).to include(">*</span>")
  end

  it "falls back to generated fields when a bespoke affordance is invalid" do
    schema_wrapper = create(
      :schema_wrapper,
      document: create(:document, :with_name_schema)
    )
    document = create(
      :document,
      domain: schema_wrapper.domain,
      schema_document: schema_wrapper.document
    )
    draft = create(:draft, document:, body: {})
    edit_document = create(
      :document,
      :with_head_revision,
      domain: schema_wrapper.domain,
      head_body: {
        "version" => 1,
        "rows" => [
          [
            {
              "kind" => "unknown"
            }
          ]
        ]
      }
    )
    edit_affordance = build(
      :edit_affordance,
      schema_wrapper:,
      edit_document:
    )
    edit_affordance.save!(validate: false)

    get draft_path(draft, edit_affordance_id: edit_affordance.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Name")
    expect(response.body).not_to include("No edit affordance projection available")
  end
end
