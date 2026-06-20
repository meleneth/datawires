# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Draft schema properties", type: :request do
  let(:draft) do
    create(
      :draft,
      body: {
        "$schema" => Document::JSON_SCHEMA_2020_12,
        "$id" => "http://example.test/schemas/example",
        "type" => "object",
        "properties" => {},
        "required" => []
      }
    )
  end

  it "adds a property to the schema draft" do
    patch add_draft_schema_properties_path(draft, format: :turbo_stream), params: {
      path: "/",
      name: "name",
      property_type: "string",
      required: "1"
    }

    expect(response).to have_http_status(:ok)
    expect(draft.reload.body).to include(
      "properties" => {
        "name" => { "type" => "string" }
      },
      "required" => [ "name" ]
    )
  end

  it "renames a property on the schema draft" do
    draft.update!(
      body: draft.body.merge(
        "properties" => { "old_name" => { "type" => "string" } },
        "required" => [ "old_name" ]
      )
    )

    patch rename_draft_schema_properties_path(draft, format: :turbo_stream), params: {
      path: "/",
      old_name: "old_name",
      new_name: "new_name"
    }

    expect(response).to have_http_status(:ok)
    expect(draft.reload.body["properties"]).to include("new_name" => { "type" => "string" })
    expect(draft.body["properties"]).not_to include("old_name")
    expect(draft.body["required"]).to eq([ "new_name" ])
  end
end

RSpec.describe "Route ownership", type: :routing do
  it "does not expose unused document_properties routes" do
    expect(patch: "/document_properties/add").not_to be_routable
  end

  it "does not expose unused room routes" do
    expect(get: "/rooms").not_to be_routable
  end

  it "does not expose unused draft update routes" do
    expect(patch: "/drafts/#{SecureRandom.uuid}").not_to be_routable
  end
end
