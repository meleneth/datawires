# frozen_string_literal: true

require "rails_helper"

RSpec.describe Boards::BodyValidator do
  subject(:validator) { described_class.new(body) }

  let(:body) do
    {
      "version" => 1,
      "title" => "Datawires Board",
      "description" => "Workspace",
      "layout" => { "columns" => 2 },
      "sections" => [
        {
          "id" => "proposals",
          "kind" => "document_collection",
          "title" => "Open proposals",
          "config" => {
            "schema_key" => "proposal",
            "filters" => [ { "path" => "/status", "operator" => "eq", "value" => "open" } ],
            "order" => { "by" => "updated_at", "direction" => "desc" },
            "limit" => 10,
            "navigation" => "document"
          }
        }
      ],
      "actions" => [
        { "id" => "submit", "kind" => "open_edit_affordance", "title" => "Submit proposal" }
      ]
    }
  end

  it "accepts a constrained version 1 board" do
    expect(validator).to be_valid
  end

  it "rejects unknown kinds and duplicate ids" do
    body["sections"] << { "id" => "proposals", "kind" => "analytics", "title" => "Other" }

    expect(validator).not_to be_valid
    expect(validator.errors).to include("sections[1].kind must be one of: document_collection, summary")
    expect(validator.errors).to include("sections ids must be unique: proposals")
  end

  it "rejects unsafe collection query shapes" do
    config = body["sections"].first["config"]
    config["filters"] = [ { "path" => "status", "operator" => "contains", "value" => "open" } ]
    config["limit"] = 101
    config["navigation"] = "view_affordance"

    expect(validator).not_to be_valid
    expect(validator.errors).to include("sections[0].config.filters[0].path must be a JSON Pointer")
    expect(validator.errors).to include("sections[0].config.filters[0].operator must be one of: eq")
    expect(validator.errors).to include("sections[0].config.limit must be between 1 and 100")
    expect(validator.errors).to include("sections[0].config.view_affordance must be a non-empty string")
  end
end
