# frozen_string_literal: true

require "rails_helper"

RSpec.describe Boards::DocumentCollection do
  it "filters, orders, limits, and selects a view affordance within the board domain" do
    domain = create(:domain)
    target_schema = create(:document, :with_schema_head_revision, domain:, key: "proposal")
    target_wrapper = create(:schema_wrapper, document: target_schema)
    matching = create(:document, :with_head_revision, domain:, schema_document: target_schema, key: "matching", title: "Zulu", head_body: { "status" => "open" })
    create(:document, :with_head_revision, domain:, schema_document: target_schema, key: "older", title: "Alpha", head_body: { "status" => "open" })
    create(:document, :with_head_revision, domain:, schema_document: target_schema, key: "closed", title: "Beta", head_body: { "status" => "closed" })
    view_affordance = create(:view_affordance, schema_wrapper: target_wrapper, title: "Summary")
    board = create_board(
      domain:,
      config: {
        "schema_key" => "proposal",
        "filters" => [ { "path" => "/status", "value" => "open" } ],
        "order" => { "by" => "title", "direction" => "desc" },
        "limit" => 1,
        "navigation" => "view_affordance",
        "view_affordance" => "Summary"
      }
    )

    result = described_class.call(board:, section: board.projection.sections.first)

    expect(result.documents).to eq([ matching ])
    expect(result.view_affordance).to eq(view_affordance)
    expect(result.error).to be_nil
  end

  it "returns a safe configuration error for a missing schema" do
    board = create_board(domain: create(:domain), config: { "schema_key" => "missing" })

    result = described_class.call(board:, section: board.projection.sections.first)

    expect(result.documents).to be_empty
    expect(result.error).to eq("Schema missing was not found.")
  end

  def create_board(domain:, config:)
    target_schema = create(:document, :with_schema_head_revision, domain:, key: "workspace")
    target_wrapper = create(:schema_wrapper, document: target_schema)
    board_schema = create(:document, :with_schema_head_revision, domain:, key: Boards::Schema::KEY, head_body: Boards::Schema::BODY)
    create(:schema_wrapper, document: board_schema)
    body = {
      "version" => 1,
      "title" => "Workspace",
      "sections" => [
        { "id" => "items", "kind" => "document_collection", "title" => "Items", "config" => config }
      ],
      "actions" => []
    }
    board_document = create(:document, :with_head_revision, domain:, schema_document: board_schema, head_body: body)
    create(:board, schema_wrapper: target_wrapper, board_document:, title: "Workspace")
  end
end
