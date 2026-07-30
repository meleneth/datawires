# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateBoard do
  it "creates a schema-backed board draft and selects the first board by default" do
    schema_wrapper = create(:schema_wrapper)
    actor = create(:user)

    result = described_class.call(schema_wrapper:, title: "Workspace", actor:)

    expect(result.board).to be_persisted
    expect(result.document.domain).to eq(schema_wrapper.domain)
    expect(result.document.schema_document.key).to eq("datawires-board")
    expect(result.draft.created_by).to eq(actor)
    expect(result.draft.body).to include(
      "version" => 1,
      "title" => "Workspace",
      "sections" => [],
      "actions" => []
    )
    expect(schema_wrapper.reload.default_board).to eq(result.board)
    expect(result.document.schema_document.schema_wrapper).to be_present
  end

  it "does not replace an existing default board" do
    schema_wrapper = create(:schema_wrapper)
    actor = create(:user)
    first = described_class.call(schema_wrapper:, title: "First", actor:).board

    described_class.call(schema_wrapper:, title: "Second", actor:)

    expect(schema_wrapper.reload.default_board).to eq(first)
  end

  it "creates a board from an immutable data definition" do
    schema_wrapper = create(:schema_wrapper)

    result = described_class.call(
      schema_wrapper:,
      title: "Assembly Workspace",
      actor: create(:user),
      definition: Boards::Definitions.body_workspace
    )

    expect(result.board.body).to include(
      "title" => "Assembly Workspace",
      "sections" => include(
        include("id" => "active-or-upcoming-meeting", "kind" => "meeting_collection"),
        include("id" => "open-proposals", "kind" => "proposal_collection"),
        include("id" => "recent-agreements", "kind" => "document_collection"),
        include("id" => "completed-meetings", "kind" => "meeting_collection")
      ),
      "actions" => include(
        include("id" => "create-meeting", "kind" => "invoke_command"),
        include("id" => "submit-proposal", "kind" => "invoke_command")
      )
    )
    expect(result.draft.body).to eq(result.board.body)
    expect(Boards::Definitions.body_workspace.fetch("title")).to eq("Datawires Board")
  end

  it "rejects an invalid data definition before writing" do
    schema_wrapper = create(:schema_wrapper)
    count = Board.count

    expect {
      described_class.call(
        schema_wrapper:,
        title: "Invalid",
        actor: create(:user),
        definition: { "version" => 1 }
      )
    }.to raise_error(ArgumentError, /sections must be an array/)
    expect(Board.count).to eq(count)
  end
end
