# frozen_string_literal: true

require "fileutils"
require "json"

actor = User.find_or_create_by!(name: "Playwright Workspace")
domain = Domain.create!(name: "Playwright Workspace #{SecureRandom.hex(4)}", owner: actor, public: true)
project = Projects::Install.call(domain:, actor:, title: "Signals Workspace", description: "Browser acceptance workspace")
workspace_schema = domain.documents.create!(key: "workspace", title: "Workspace")
schema_revision = workspace_schema.revisions.create!(body: {
  "$schema" => Document::JSON_SCHEMA_2020_12, "$id" => "playwright:workspace", "type" => "object",
  "properties" => { "title" => { "type" => "string" } }
}, created_by: actor)
workspace_schema.update!(head_revision: schema_revision)
wrapper = SyncSchemaWrapperForDocument.call(document: workspace_schema)
board = CreateBoard.call(schema_wrapper: wrapper, title: "Operations", actor:, definition: {
  "version" => 1, "title" => "Operations", "description" => "Live signals", "layout" => { "provider" => "grid" },
  "columns" => [ { "id" => "signals", "title" => "Signals", "cards" => [
    { "id" => "temperature", "kind" => "graph", "title" => "Temperature",
      "config" => { "metric_key" => "temperature", "renderer" => "line", "bucket_seconds" => 60 } }
  ] } ], "sections" => [], "actions" => []
}).board
project.update!(default_board: board)
source = Sources::Create.call(domain:, actor:, title: "Weather API", adapter: "http_json",
  config: { "url" => "https://example.test/weather", "method" => "GET" },
  observation: { "type" => "metric", "metric_key" => "temperature", "unit" => "C", "value_pointer" => "/value" })
run = source.source_runs.create!(configuration_revision: source.head_revision, trigger: "manual", adapter: "http_json",
  adapter_version: "1", idempotency_key: SecureRandom.uuid, status: "succeeded", observation_count: 3)
3.times do |index|
  time = (3 - index).minutes.ago
  source.observations.create!(domain:, source_run: run, configuration_revision: source.head_revision,
    observation_type: "metric", metric_key: "temperature", unit: "C", numeric_value: 20 + index,
    dimensions: { "site" => "north" }, payload: { "value" => 20 + index }, observed_at: time,
    effective_at: time, recorded_at: time, provenance: { "configuration_revision_id" => source.head_revision.id })
end

FileUtils.mkdir_p(Rails.root.join("tmp", "playwright"))
File.write(Rails.root.join("tmp", "playwright", "project_workspace.json"), JSON.pretty_generate(
  "domainPath" => Rails.application.routes.url_helpers.domain_path(domain),
  "boardPath" => Rails.application.routes.url_helpers.board_path(board)
))
