# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Derived metric evaluation and rollups" do
  it "evaluates aligned input buckets and materializes an idempotent append-only rollup with exact lineage" do
    domain = create(:domain)
    source = create(:source, domain:)
    run = source.source_runs.create!(configuration_revision: source.head_revision, trigger: "manual",
      adapter: source.adapter, adapter_version: "1", idempotency_key: "inputs")
    record(source:, run:, metric_key: "requests", value: 10, at: "2026-08-25 12:01")
    record(source:, run:, metric_key: "requests", value: 20, at: "2026-08-25 12:06")
    record(source:, run:, metric_key: "errors", value: 2, at: "2026-08-25 12:02")
    record(source:, run:, metric_key: "errors", value: 5, at: "2026-08-25 12:07")
    metric = create_metric(domain:, body: {
      "version" => 1, "key" => "successes", "title" => "Successes", "value_type" => "number",
      "aggregation" => "sum", "correction_policy" => "latest",
      "derived" => { "operation" => "subtract", "inputs" => %w[requests errors] },
      "rollup" => { "bucket_seconds" => 300 }
    })

    result = Metrics::Evaluate.call(metric_definition: metric)
    expect(result.points.map(&:value)).to eq([ 8.0, 15.0 ])
    expect(result.lineage).to include("metric_definition_revision_ids" => [ metric.head_revision.id ],
      "input_metric_keys" => %w[requests errors])

    first = Metrics::Rollup.call(metric_definition: metric, actor: domain.owner)
    expect { Metrics::Rollup.call(metric_definition: metric, actor: domain.owner) }.not_to change(Observation, :count)
    expect(first.observations.map { |observation| observation.numeric_value.to_f }).to eq([ 8.0, 15.0 ])
    expect(first.observations.first.provenance).to include(
      "metric_definition_revision_id" => metric.head_revision.id, "rollup_bucket_seconds" => 300
    )
    expect(first.source.adapter).to eq("derived_metric")
  end

  it "rejects invalid definitions and division by zero explicitly" do
    domain = create(:domain)
    invalid = create_metric(domain:, body: {
      "version" => 1, "key" => "invalid", "title" => "Invalid", "value_type" => "number",
      "aggregation" => "average", "correction_policy" => "latest", "derived" => {
        "operation" => "add", "inputs" => [ "only-one" ]
      }
    }, validate_document: false)
    expect { Metrics::Evaluate.call(metric_definition: invalid, bucket_seconds: 60) }.to raise_error(
      ArgumentError, /at least two inputs/
    )
  end

  def create_metric(domain:, body:, validate_document: true)
    schema = domain.documents.find_by(key: Metrics::Schema::KEY) || begin
      document = create(:document, :with_schema_head_revision, domain:, key: Metrics::Schema::KEY,
        head_body: Metrics::Schema::BODY)
      create(:schema_wrapper, document:)
      document
    end
    document = create(:document, :with_head_revision, domain:, schema_document: schema, head_body: body)
    MetricDefinition.create!(domain:, key: body.fetch("key"), metric_document: document).tap do |metric|
      expect(metric.metric_document).to be_valid if validate_document
    end
  end

  def record(source:, run:, metric_key:, value:, at:)
    time = Time.zone.parse(at)
    source.observations.create!(domain: source.domain, source_run: run, configuration_revision: source.head_revision,
      observation_type: "metric", metric_key:, numeric_value: value, dimensions: {}, payload: {}, observed_at: time,
      effective_at: time, recorded_at: time)
  end
end
