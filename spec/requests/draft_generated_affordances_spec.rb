# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Generated draft affordances", type: :request do
  it "renders generated fields for schema-backed drafts without a stored edit affordance" do
    schema_wrapper = create(
      :schema_wrapper,
      document: create(
        :document,
        :with_head_revision,
        head_body: {
          "$schema" => Document::JSON_SCHEMA_2020_12,
          "$id" => "http://example.test/schemas/generated-render",
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

    get draft_path(draft)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("No edit affordance projection available")
    expect(response.body).to include("Display Name")
    expect(response.body).to include(">*</span>")
  end
end
