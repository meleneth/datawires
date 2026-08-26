# frozen_string_literal: true

require "rails_helper"

RSpec.describe Observations::Query do
  it "filters dimensions, applies corrections, buckets values, and returns lineage" do
    source = create(:source)
    run = source.source_runs.create!(configuration_revision: source.head_revision, trigger: "manual",
      adapter: "http_json", adapter_version: "1", idempotency_key: SecureRandom.uuid)
    first = observation(source:, run:, value: 10, at: Time.zone.parse("2026-08-25 12:01"), site: "north")
    observation(source:, run:, value: 20, at: Time.zone.parse("2026-08-25 12:04"), site: "north")
    observation(source:, run:, value: 99, at: Time.zone.parse("2026-08-25 12:04"), site: "south")
    replacement = Observations::Correct.call(observation: first, kind: "replace", numeric_value: 14,
      payload: { "value" => 14 })

    result = described_class.call(domain: source.domain, metric_key: "temperature", dimensions: { "site" => "north" },
      bucket_seconds: 300, aggregate: "average")

    expect(result.points.map(&:value)).to eq([ 17.0 ])
    expect(result.statistics).to include("count" => 2, "min" => 14.0, "max" => 20.0, "average" => 17.0)
    expect(result.lineage["observation_ids"]).to contain_exactly(replacement.id, Observation.where(numeric_value: 20).sole.id)
    expect(result.lineage["configuration_revision_ids"]).to eq([ source.head_revision.id ])
  end

  private

  def observation(source:, run:, value:, at:, site:)
    source.observations.create!(domain: source.domain, source_run: run, configuration_revision: source.head_revision,
      observation_type: "metric", metric_key: "temperature", unit: "C", numeric_value: value,
      dimensions: { "site" => site }, payload: { "value" => value }, observed_at: at, effective_at: at,
      recorded_at: Time.current)
  end
end
