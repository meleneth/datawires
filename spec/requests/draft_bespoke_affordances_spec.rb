# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bespoke draft affordances", type: :request do
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
    edit_affordance = create(
      :edit_affordance,
      schema_wrapper:,
      edit_document:
    )

    get draft_path(draft, edit_affordance_id: edit_affordance.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<textarea")
    expect(response.body).to include("Already here")
  end
end
