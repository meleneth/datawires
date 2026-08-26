# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project board authoring", type: :request do
  it "creates a default project board and versions layout, columns, and cards" do
    domain = create(:domain)
    project = Projects::Install.call(domain:)

    expect {
      post domain_project_boards_path(domain)
    }.to change(Board, :count).by(1)

    board = project.reload.default_board
    expect(response).to redirect_to(board_path(board))
    expect(board.body).to include("layout" => { "provider" => "kanban" }, "columns" => [])
    initial_revision = board.head_revision

    post add_column_board_configuration_path(board), params: { title: "Doing" }
    expect(board.reload.body["columns"]).to include(include("id" => "doing", "title" => "Doing"))
    expect(board.head_revision.parent_revision).to eq(initial_revision)

    post add_card_board_configuration_path(board), params: {
      column_id: "doing", kind: "metric", title: "Temperature", metric_key: "temperature", statistic: "last"
    }
    card = board.reload.body["columns"].first["cards"].sole
    expect(card).to include("kind" => "metric", "config" => include("metric_key" => "temperature"))

    patch update_layout_board_configuration_path(board), params: { provider: "grid" }
    expect(board.reload.body["layout"]).to eq("provider" => "grid")

    delete remove_card_board_configuration_path(board), params: { column_id: "doing", card_id: card["id"] }
    expect(board.reload.body["columns"].first["cards"]).to be_empty
    expect(board.board_document.revisions.count).to eq(5)
  end

  it "does not expose project authoring controls on a legacy board" do
    board = create(:board)

    get board_path(board)

    expect(response.body).not_to include("Add column")
    expect(response.body).not_to include("Add card")
  end

  it "reorders columns and cards across versioned revisions and parses provider configuration" do
    domain = create(:domain)
    project = Projects::Install.call(domain:)
    post domain_project_boards_path(domain)
    board = project.reload.default_board
    %w[First Second].each { |title| post add_column_board_configuration_path(board), params: { title: } }
    %w[One Two].each do |title|
      post add_card_board_configuration_path(board), params: {
        column_id: "first", kind: "query", title:, query_key: "daily", dimensions: '{"site":"north"}'
      }
    end

    patch move_column_board_configuration_path(board), params: { column_id: "second", direction: "up" }
    expect(board.reload.body["columns"].pluck("id")).to eq(%w[second first])

    patch move_card_board_configuration_path(board), params: { column_id: "first", card_id: "two", direction: "up" }
    cards = board.reload.body["columns"].find { |column| column["id"] == "first" }.fetch("cards")
    expect(cards.pluck("id")).to eq(%w[two one])
    expect(cards.first["config"]).to include("query_key" => "daily", "dimensions" => { "site" => "north" })

    patch move_card_board_configuration_path(board), params: {
      column_id: "first", target_column_id: "second", card_id: "two", direction: "down"
    }
    expect(board.reload.body["columns"].find { |column| column["id"] == "second" }.fetch("cards").pluck("id")).to eq([ "two" ])

    patch move_column_board_configuration_path(board), params: { column_id: "first", target_column_id: "second" }
    expect(board.reload.body["columns"].pluck("id")).to eq(%w[first second])

    patch move_card_board_configuration_path(board), params: {
      column_id: "second", target_column_id: "first", target_card_id: "one", card_id: "two"
    }
    expect(board.reload.body["columns"].first.fetch("cards").pluck("id")).to eq(%w[two one])
  end
end
