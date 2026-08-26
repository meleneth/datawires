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

  it "covers every aggregate with one explicit value table" do
    source = create(:source)
    run = source.source_runs.create!(configuration_revision: source.head_revision, trigger: "manual",
      adapter: "http_json", adapter_version: "1", idempotency_key: SecureRandom.uuid)
    [ 3, 7, 5 ].each_with_index do |value, minute|
      observation(source:, run:, value:, at: Time.zone.parse("2026-08-25 12:0#{minute}"), site: "north")
    end

    expected = { "count" => 3.0, "sum" => 15.0, "min" => 3.0, "max" => 7.0, "last" => 5.0,
                 "average" => 5.0 }
    expected.each do |aggregate, value|
      result = described_class.call(domain: source.domain, metric_key: "temperature", bucket_seconds: 300, aggregate:)
      expect(result.points.sole.value).to eq(value), "expected #{aggregate} aggregation"
    end
  end

  it "applies source and time filters and returns the empty statistics contract" do
    source = create(:source)
    other_document = create(:document, :with_head_revision, domain: source.domain,
      schema_document: source.source_document.schema_document, head_body: source.body.merge("title" => "Other"))
    other_source = Source.create!(domain: source.domain, source_document: other_document)
    run = source.source_runs.create!(configuration_revision: source.head_revision, trigger: "manual",
      adapter: "http_json", adapter_version: "1", idempotency_key: SecureRandom.uuid)
    observation(source:, run:, value: 10, at: Time.zone.parse("2026-08-25 12:00"), site: "north")

    result = described_class.call(domain: source.domain, metric_key: "temperature", source_id: other_source.id,
      from: Time.zone.parse("2026-08-25 13:00"), to: Time.zone.parse("2026-08-25 14:00"))

    expect(result.points).to be_empty
    expect(result.statistics).to eq(
      "count" => 0, "sum" => 0.0, "min" => nil, "max" => nil, "average" => nil, "last" => nil
    )
    expect(result.lineage).to include("observation_ids" => [], "source_run_ids" => [],
      "configuration_revision_ids" => [])
  end

  private

  def observation(source:, run:, value:, at:, site:)
    source.observations.create!(domain: source.domain, source_run: run, configuration_revision: source.head_revision,
      observation_type: "metric", metric_key: "temperature", unit: "C", numeric_value: value,
      dimensions: { "site" => site }, payload: { "value" => value }, observed_at: at, effective_at: at,
      recorded_at: Time.current)
  end
end
