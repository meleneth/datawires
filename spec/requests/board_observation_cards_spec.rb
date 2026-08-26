# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Board observation cards", type: :request do
  it "renders metric, reusable query, and every registered series renderer through providers" do
    board = create(:board)
    source = create(:source, domain: board.schema_wrapper.domain)
    run = source.source_runs.create!(configuration_revision: source.head_revision, trigger: "manual",
      adapter: "http_json", adapter_version: "1", idempotency_key: SecureRandom.uuid)
    3.times do |index|
      source.observations.create!(domain: source.domain, source_run: run, configuration_revision: source.head_revision,
        observation_type: "metric", metric_key: "temperature", numeric_value: 10 + index,
        payload: {}, observed_at: index.minutes.ago, effective_at: index.minutes.ago, recorded_at: Time.current)
    end
    VersionedDefinitions::Create.call(domain: source.domain, actor: source.domain.owner, schema: Queries::Schema,
      key: "temperature-stats", title: "Temperature stats", wrapper_class: QueryDefinition,
      document_association: :query_document, body: {
        "version" => 1, "key" => "temperature-stats", "title" => "Temperature stats",
        "metric_key" => "temperature", "aggregate" => "average"
      })
    body = board.body.deep_dup.merge(
      "layout" => { "provider" => "grid" },
      "columns" => [
        {
          "id" => "signals", "title" => "Signals", "cards" => [
            { "id" => "latest", "kind" => "metric", "title" => "Latest", "config" => { "metric_key" => "temperature" } },
            { "id" => "stats", "kind" => "query", "title" => "Statistics", "config" => { "query_key" => "temperature-stats" } },
            { "id" => "line", "kind" => "graph", "title" => "Line", "config" => { "metric_key" => "temperature", "renderer" => "line" } },
            { "id" => "spark", "kind" => "graph", "title" => "Spark", "config" => { "metric_key" => "temperature", "renderer" => "sparkline" } },
            { "id" => "area", "kind" => "graph", "title" => "Area", "config" => { "metric_key" => "temperature", "renderer" => "area" } },
            { "id" => "bar", "kind" => "graph", "title" => "Bar", "config" => { "metric_key" => "temperature", "renderer" => "bar" } }
          ]
        }
      ]
    )
    revision = board.board_document.revisions.create!(body:, parent_revision: board.head_revision)
    board.board_document.update!(head_revision: revision)

    get board_path(board)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Latest", "Statistics", "Line", "Spark", "Area", "Bar")
    expect(response.body.scan("data-controller=\"series-chart\"").length).to eq(4)
  end
end
