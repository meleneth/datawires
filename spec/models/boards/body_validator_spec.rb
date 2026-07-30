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
        {
          "id" => "submit",
          "kind" => "open_edit_affordance",
          "title" => "Submit proposal",
          "config" => { "schema_key" => "proposal" }
        }
      ]
    }
  end

  it "requires typed action targets" do
    body["actions"] = [
      { "id" => "edit", "kind" => "open_edit_affordance", "title" => "Edit", "config" => {} },
      { "id" => "command", "kind" => "invoke_command", "title" => "Run", "config" => {} }
    ]

    expect(validator).not_to be_valid
    expect(validator.errors).to include("actions[0].config.schema_key must be a non-empty string")
    expect(validator.errors).to include("actions[1].config.command must be a non-empty string")
  end

  it "accepts a constrained version 1 board" do
    expect(validator).to be_valid
  end

  it "accepts a meeting collection constrained by projection status" do
    body["sections"] = [
      {
        "id" => "recent-meetings",
        "kind" => "meeting_collection",
        "title" => "Recent meetings",
        "config" => {
          "statuses" => %w[adjourned],
          "order" => { "by" => "scheduled_at", "direction" => "desc" },
          "limit" => 5,
          "navigation" => "document"
        }
      }
    ]

    expect(validator).to be_valid
  end

  it "rejects an unbounded meeting collection" do
    body["sections"] = [
      {
        "id" => "meetings",
        "kind" => "meeting_collection",
        "title" => "Meetings",
        "config" => {
          "statuses" => [],
          "order" => { "by" => "title" }
        }
      }
    ]

    expect(validator).not_to be_valid
    expect(validator.errors).to include("sections[0].config.statuses must be a non-empty array of strings")
    expect(validator.errors).to include(
      "sections[0].config.order.by must be one of: scheduled_at, created_at, updated_at"
    )
  end

  it "accepts a proposal collection constrained by derived state" do
    body["sections"] = [
      {
        "id" => "open-proposals",
        "kind" => "proposal_collection",
        "title" => "Open proposals",
        "config" => {
          "states" => %w[open],
          "order" => { "by" => "submitted_at", "direction" => "desc" },
          "limit" => 10
        }
      }
    ]

    expect(validator).to be_valid
  end

  it "rejects unknown proposal states" do
    body["sections"] = [
      {
        "id" => "proposals",
        "kind" => "proposal_collection",
        "title" => "Proposals",
        "config" => { "states" => %w[adopted] }
      }
    ]

    expect(validator).not_to be_valid
    expect(validator.errors).to include("sections[0].config.states must contain only: open, decided")
  end

  it "rejects unknown kinds and duplicate ids" do
    body["sections"] << { "id" => "proposals", "kind" => "analytics", "title" => "Other" }

    expect(validator).not_to be_valid
    expect(validator.errors).to include(
      "sections[1].kind must be one of: document_collection, meeting_collection, proposal_collection, " \
      "membership_collection, role_assignment_collection, summary"
    )
    expect(validator.errors).to include("sections ids must be unique: proposals")
  end

  it "accepts constrained relationship collections" do
    body["sections"] = [
      {
        "id" => "members",
        "kind" => "membership_collection",
        "title" => "Members",
        "config" => { "limit" => 50, "empty_state" => "No members." }
      },
      {
        "id" => "roles",
        "kind" => "role_assignment_collection",
        "title" => "Roles",
        "config" => { "limit" => 50, "empty_state" => "No roles." }
      }
    ]

    expect(validator).to be_valid
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
