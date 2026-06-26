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

  it "navigates between affordance screens" do
    schema_wrapper = create(
      :schema_wrapper,
      document: create(
        :document,
        :with_head_revision,
        head_body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "http://example.test/schemas/profile",
          "type" => "object",
          "properties" => {
            "name" => { "type" => "string" },
            "bio" => {
              "type" => "string",
              "title" => "Biography"
            }
          }
        }
      )
    )
    document = create(
      :document,
      domain: schema_wrapper.domain,
      schema_document: schema_wrapper.document
    )
    draft = create(:draft, document:, body: { "name" => "Ada", "bio" => "First programmer" })
    edit_document = create(
      :document,
      :with_head_revision,
      domain: schema_wrapper.domain,
      head_body: {
        "version" => 1,
        "start_screen" => "summary",
        "screens" => [
          {
            "id" => "summary",
            "title" => "Summary",
            "rows" => [
              [
                {
                  "binding" => {
                    "kind" => "document_ptr",
                    "ptr" => "/name"
                  }
                },
                {
                  "kind" => "navigation",
                  "target_screen" => "details",
                  "label" => "Edit details"
                }
              ]
            ]
          },
          {
            "id" => "details",
            "title" => "Details",
            "rows" => [
              [
                {
                  "binding" => {
                    "kind" => "document_ptr",
                    "ptr" => "/bio"
                  },
                  "widget" => "textarea"
                }
              ]
            ]
          }
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
    expect(response.body).to include("Edit details")
    expect(response.body).to include("screen=details")
    expect(response.body).to include("Ada")
    expect(response.body).not_to include("Biography")

    get draft_path(draft, edit_affordance_id: edit_affordance.id, screen: "details")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Biography")
    expect(response.body).to include("First programmer")
  end

  it "renders immediate commit actions for screens configured to commit immediately" do
    schema_wrapper = create(
      :schema_wrapper,
      document: create(:document, :with_name_schema)
    )
    document = create(
      :document,
      domain: schema_wrapper.domain,
      schema_document: schema_wrapper.document
    )
    draft = create(:draft, document:, body: { "name" => "Ada" })
    edit_document = create(
      :document,
      :with_head_revision,
      domain: schema_wrapper.domain,
      head_body: {
        "version" => 1,
        "commit_mode" => "immediate",
        "screens" => [
          {
            "id" => "summary",
            "rows" => [
              [
                {
                  "binding" => {
                    "kind" => "document_ptr",
                    "ptr" => "/name"
                  }
                },
                {
                  "kind" => "commit"
                }
              ]
            ]
          }
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
    commit_forms = parsed_body.css(%(form[action*="#{draft_commit_path(draft)}"]))
    expect(commit_forms).not_to be_empty
    expect(commit_forms.first["action"]).to include("screen=summary")

    post draft_commit_path(draft, edit_affordance_id: edit_affordance.id, screen: "summary"), params: {
      commit: {
        message: ""
      }
    }

    expect(response).to redirect_to(document_path(document))
    expect(Draft.exists?(draft.id)).to be(false)
    expect(document.reload.body).to eq("name" => "Ada")
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

  it "renders base64 image widgets as image previews with editable source text" do
    schema_wrapper = create(
      :schema_wrapper,
      document: create(
        :document,
        :with_head_revision,
        head_body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "http://example.test/schemas/card",
          "type" => "object",
          "properties" => {
            "thumbnail" => {
              "type" => "string",
              "title" => "Thumbnail"
            }
          }
        }
      )
    )
    document = create(
      :document,
      domain: schema_wrapper.domain,
      schema_document: schema_wrapper.document
    )
    image_payload = "iVBORw0KGgo="
    draft = create(:draft, document:, body: { "thumbnail" => image_payload })
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
                "ptr" => "/thumbnail"
              },
              "widget" => "base64_image"
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
    image = html.at_css("img[alt='Thumbnail']")
    textarea = html.at_css("textarea#field_thumbnail")

    expect(response).to have_http_status(:ok)
    expect(image["src"]).to eq("data:image/png;base64,#{image_payload}")
    expect(textarea.text).to include(image_payload)
    expect(textarea["data-action"]).to eq("input->autosave#queue change->autosave#submit")
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
