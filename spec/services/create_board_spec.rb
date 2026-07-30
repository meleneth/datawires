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
end
