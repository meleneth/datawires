# frozen_string_literal: true

module Metrics
  class Rollup
    def self.call(metric_definition:, actor: nil, dimensions: {}, from: nil, to: nil, bucket_seconds: nil)
      new(metric_definition:, actor:, dimensions:, from:, to:, bucket_seconds:).call
    end

    def initialize(metric_definition:, actor:, dimensions:, from:, to:, bucket_seconds:)
      @metric = metric_definition
      @actor = actor
      @dimensions = dimensions
      @from = from
      @to = to
      @bucket_seconds = bucket_seconds || metric.body.dig("rollup", "bucket_seconds")
    end

    def call
      result = Metrics::Evaluate.call(metric_definition: metric, dimensions:, from:, to:, bucket_seconds:)
      source = rollup_source
      run = source.source_runs.find_or_create_by!(idempotency_key:) do |candidate|
        candidate.configuration_revision = source.head_revision
        candidate.triggered_by = actor
        candidate.trigger = "manual"
        candidate.adapter = "derived_metric"
        candidate.adapter_version = Sources::Adapters::DerivedMetric::VERSION
      end
      return run unless run.status == "pending"

      now = Time.current
      run.update!(status: "running", started_at: now)
      observations = result.points.map do |point|
        source.observations.create!(domain: metric.domain, source_run: run,
          configuration_revision: source.head_revision, observation_type: "rollup", metric_key: metric.key,
          unit: metric.body["unit"], numeric_value: point.value, dimensions:, payload: { "count" => point.count },
          observed_at: point.time, effective_at: point.time, recorded_at: now,
          provenance: result.lineage.merge("metric_definition_id" => metric.id,
            "metric_definition_revision_id" => metric.head_revision.id, "rollup_bucket_seconds" => bucket_seconds.to_i))
      end
      run.update!(status: "succeeded", finished_at: Time.current, observation_count: observations.length,
        metadata: { "metric_definition_revision_id" => metric.head_revision.id })
      source.update!(status: "succeeded", last_succeeded_at: run.finished_at)
      run
    rescue StandardError => e
      run&.update!(status: "failed", finished_at: Time.current, error_class: e.class.name, error_message: e.message)
      raise
    end

    private

    attr_reader :metric, :actor, :dimensions, :from, :to, :bucket_seconds

    def rollup_source
      metric.domain.sources.includes(source_document: :head_revision).find do |source|
        source.adapter == "derived_metric" && source.body.dig("config", "metric_key") == metric.key
      end || Sources::Create.call(domain: metric.domain, actor:, title: "#{metric.body['title']} rollup",
        adapter: "derived_metric", config: { "metric_key" => metric.key },
        observation: { "type" => "rollup", "metric_key" => metric.key, "unit" => metric.body["unit"] })
    end

    def idempotency_key
      Digest::SHA256.hexdigest([ metric.head_revision.id, from&.iso8601, to&.iso8601, bucket_seconds,
        dimensions.sort ].to_json)
    end
  end
end
