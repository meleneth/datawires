# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Board observation cards", type: :request do
  it "renders metric, query, line, and sparkline cards through providers" do
    board = create(:board)
    source = create(:source, domain: board.schema_wrapper.domain)
    run = source.source_runs.create!(configuration_revision: source.head_revision, trigger: "manual",
      adapter: "http_json", adapter_version: "1", idempotency_key: SecureRandom.uuid)
    3.times do |index|
      source.observations.create!(domain: source.domain, source_run: run, configuration_revision: source.head_revision,
        observation_type: "metric", metric_key: "temperature", numeric_value: 10 + index,
        payload: {}, observed_at: index.minutes.ago, effective_at: index.minutes.ago, recorded_at: Time.current)
    end
    body = board.body.deep_dup.merge(
      "layout" => { "provider" => "grid" },
      "columns" => [
        {
          "id" => "signals", "title" => "Signals", "cards" => [
            { "id" => "latest", "kind" => "metric", "title" => "Latest", "config" => { "metric_key" => "temperature" } },
            { "id" => "stats", "kind" => "query", "title" => "Statistics", "config" => { "metric_key" => "temperature" } },
            { "id" => "line", "kind" => "graph", "title" => "Line", "config" => { "metric_key" => "temperature", "renderer" => "line" } },
            { "id" => "spark", "kind" => "graph", "title" => "Spark", "config" => { "metric_key" => "temperature", "renderer" => "sparkline" } }
          ]
        }
      ]
    )
    revision = board.board_document.revisions.create!(body:, parent_revision: board.head_revision)
    board.board_document.update!(head_revision: revision)

    get board_path(board)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Latest", "Statistics", "Line", "Spark")
    expect(response.body.scan("data-controller=\"series-chart\"").length).to eq(2)
  end
end
