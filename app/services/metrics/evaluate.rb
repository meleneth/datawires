# frozen_string_literal: true

module Metrics
  class Evaluate
    def self.call(metric_definition:, dimensions: {}, from: nil, to: nil, bucket_seconds: nil)
      new(metric_definition:, dimensions:, from:, to:, bucket_seconds:).call
    end

    def initialize(metric_definition:, dimensions:, from:, to:, bucket_seconds:)
      @metric = metric_definition
      @dimensions = dimensions
      @from = from
      @to = to
      @bucket_seconds = bucket_seconds || metric.body.dig("rollup", "bucket_seconds")
    end

    def call
      derived = metric.body.fetch("derived")
      operation = derived.fetch("operation")
      provider = Datawires::Providers.derived_operations.fetch(operation)
      raise ArgumentError, "derived operation is not registered" unless provider

      inputs = Array(derived.fetch("inputs"))
      raise ArgumentError, "derived metric requires at least two inputs" if inputs.length < 2
      raise ArgumentError, "derived metric requires a positive bucket" unless bucket_seconds.to_i.positive?

      results = inputs.map { |key| query(key) }
      point_maps = results.map { |result| result.points.index_by(&:time) }
      times = point_maps.map(&:keys).reduce { |left, right| left & right }.sort
      points = times.map do |time|
        values = point_maps.map { |map| map.fetch(time).value }
        Observations::Query::Point.new(time:, value: apply(provider, values), count: values.length)
      end
      Observations::Query::Result.new(points:, statistics: statistics(points), lineage: lineage(results, inputs))
    end

    private

    attr_reader :metric, :dimensions, :from, :to, :bucket_seconds

    def query(metric_key)
      Observations::Query.call(domain: metric.domain, metric_key:, dimensions:, from:, to:,
        bucket_seconds:, aggregate: "average")
    end

    def apply(provider, values)
      values.drop(1).reduce(values.first.to_f) { |result, value| provider.call(result, value) }
    end

    def statistics(points)
      values = points.map(&:value)
      return { "count" => 0, "sum" => 0.0, "min" => nil, "max" => nil, "average" => nil, "last" => nil } if values.empty?

      { "count" => values.length, "sum" => values.sum, "min" => values.min, "max" => values.max,
        "average" => values.sum / values.length, "last" => values.last }
    end

    def lineage(results, inputs)
      {
        "metric_definition_revision_ids" => [ metric.head_revision.id ],
        "input_metric_keys" => inputs,
        "observation_ids" => results.flat_map { |result| result.lineage["observation_ids"] }.uniq,
        "source_run_ids" => results.flat_map { |result| result.lineage["source_run_ids"] }.uniq,
        "configuration_revision_ids" => results.flat_map { |result| result.lineage["configuration_revision_ids"] }.uniq,
        "queried_at" => Time.current.iso8601
      }
    end
  end
end
