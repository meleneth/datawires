# frozen_string_literal: true

module Observations
  class Query
    Point = Data.define(:time, :value, :count)
    Result = Data.define(:points, :statistics, :lineage)

    def self.call(domain:, metric_key:, source_id: nil, dimensions: {}, from: nil, to: nil, bucket_seconds: nil,
      aggregate: "average")
      new(domain:, metric_key:, source_id:, dimensions:, from:, to:, bucket_seconds:, aggregate:).call
    end

    def initialize(domain:, metric_key:, source_id:, dimensions:, from:, to:, bucket_seconds:, aggregate:)
      @domain = domain
      @metric_key = metric_key
      @source_id = source_id
      @dimensions = dimensions || {}
      @from = from
      @to = to
      @bucket_seconds = bucket_seconds&.to_i
      @aggregate = aggregate
    end

    def call
      rows = corrected_rows
      Result.new(points: points(rows), statistics: statistics(rows), lineage: lineage(rows))
    end

    private

    attr_reader :domain, :metric_key, :source_id, :dimensions, :from, :to, :bucket_seconds, :aggregate

    def scoped_rows
      scope = domain.observations.where(metric_key:).where.not(numeric_value: nil)
      scope = scope.where(source_id:) if source_id.present?
      scope = scope.where("observed_at >= ?", from) if from
      scope = scope.where("observed_at <= ?", to) if to
      dimensions.each { |key, value| scope = scope.where("dimensions ->> ? = ?", key.to_s, value.to_s) }
      scope.order(:observed_at, :recorded_at).to_a
    end

    def corrected_rows
      rows = scoped_rows
      corrected_ids = Observation.where(corrects_observation_id: rows.map(&:id)).pluck(:corrects_observation_id).to_set
      rows.reject { |row| corrected_ids.include?(row.id) || row.correction_kind == "retract" }
    end

    def points(rows)
      return rows.map { |row| Point.new(time: row.observed_at, value: row.numeric_value.to_f, count: 1) } unless bucket_seconds&.positive?

      rows.group_by { |row| Time.at((row.observed_at.to_i / bucket_seconds) * bucket_seconds).in_time_zone }.map do |time, bucket|
        Point.new(time:, value: aggregate_values(bucket.map { |row| row.numeric_value.to_f }), count: bucket.length)
      end.sort_by(&:time)
    end

    def statistics(rows)
      values = rows.map { |row| row.numeric_value.to_f }
      return { "count" => 0, "sum" => 0.0, "min" => nil, "max" => nil, "average" => nil, "last" => nil } if values.empty?

      { "count" => values.length, "sum" => values.sum, "min" => values.min, "max" => values.max,
        "average" => values.sum / values.length, "last" => values.last }
    end

    def aggregate_values(values)
      case aggregate
      when "count" then values.length.to_f
      when "sum" then values.sum
      when "min" then values.min
      when "max" then values.max
      when "last" then values.last
      else values.sum / values.length
      end
    end

    def lineage(rows)
      {
        "observation_ids" => rows.map(&:id),
        "source_run_ids" => rows.map(&:source_run_id).uniq,
        "configuration_revision_ids" => rows.map(&:configuration_revision_id).uniq,
        "queried_at" => Time.current.iso8601
      }
    end
  end
end
