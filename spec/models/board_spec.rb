# frozen_string_literal: true

require "rails_helper"

RSpec.describe Board, type: :model do
  it { is_expected.to belong_to(:schema_wrapper) }
  it { is_expected.to belong_to(:board_document).class_name("Document") }
  it { is_expected.to validate_presence_of(:title) }

  it "projects its validated immutable presentation" do
    board = create(:board)

    expect(board.projection.title).to eq(board.title)
    expect(board.projection.sections).to eq([])
    expect(board.projection.columns).to eq([])
  end

  it "requires the backing document to share the schema domain" do
    board = build(:board, board_document: create(:document, :with_head_revision))

    expect(board).not_to be_valid
    expect(board.errors[:board_document]).to include("must belong to the schema wrapper domain")
  end

  it "rejects an invalid board body" do
    board = build(
      :board,
      board_document: create(
        :document,
        :with_head_revision,
        domain: create(:domain),
        head_body: { "version" => 1 }
      )
    )
    board.board_document.update!(domain: board.schema_wrapper.domain)

    expect(board).not_to be_valid
    expect(board.errors[:board_document]).to include("title must be a non-empty string")
  end
end
