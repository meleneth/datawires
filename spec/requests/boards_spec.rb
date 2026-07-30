# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Boards", type: :request do
  it "creates and opens a board from the schema workshop" do
    schema_wrapper = create(:schema_wrapper)

    expect {
      post schema_boards_path(schema_wrapper), params: { title: "Datawires Board" }
    }.to change(Board, :count).by(1)
      .and change(Document, :count).by(2)
      .and change(Draft, :count).by(1)

    board = Board.order(:created_at).last
    expect(response).to redirect_to(board_path(board))

    get board_path(board)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Datawires Board")
    expect(response.body).to include("This board has no sections yet.")
    expect(response.body).to include("Schema workshop")
  end

  it "prefers the default board while preserving an explicit workshop route" do
    board = create(:board)
    board.schema_wrapper.update!(default_board: board)

    get schema_path(board.schema_wrapper)
    expect(response).to redirect_to(board_path(board))

    get schema_path(board.schema_wrapper, workshop: 1)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("New board")
  end
end
