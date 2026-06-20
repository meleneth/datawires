# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Generated draft affordances", type: :request do
  it "renders generated fields for schema-backed drafts without a stored edit affordance" do
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

    get draft_path(draft)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("No edit affordance projection available")
    schema_wrapper.document.body.fetch("properties").each_key do |property_name|
      expect(response.body).to include(property_name.humanize)
    end
  end
end
