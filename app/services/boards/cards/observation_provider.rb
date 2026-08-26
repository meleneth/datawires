# frozen_string_literal: true

module Boards
  module Cards
    class ObservationProvider < BaseProvider
      class << self
        def validate(config, path: "config")
          errors = super
          unless config.is_a?(Hash) && (config["metric_key"].to_s.present? || config["query_key"].to_s.present?)
            errors << "#{path}.metric_key or #{path}.query_key must be a non-empty string"
          end
          errors
        end
      end

      private

      def query_result
        config = resolved_config
        metric = board.schema_wrapper.domain.metric_definitions.find_by(key: config["metric_key"])
        if metric&.body&.dig("derived")
          return Metrics::Evaluate.call(metric_definition: metric, dimensions: config["dimensions"] || {},
            from: parse_time(config["from"]), to: parse_time(config["to"]),
            bucket_seconds: config["bucket_seconds"])
        end

        Observations::Query.call(
          domain: board.schema_wrapper.domain,
          metric_key: config["metric_key"],
          source_id: config["source_id"],
          dimensions: config["dimensions"] || {},
          from: parse_time(config["from"]) || window_start(config),
          to: parse_time(config["to"]),
          bucket_seconds: config["bucket_seconds"],
          aggregate: config.fetch("aggregate", "average")
        )
      end

      def resolved_config
        query_key = card.config["query_key"]
        return card.config unless query_key.present?

        definition = board.schema_wrapper.domain.query_definitions.includes(query_document: :head_revision).find_by(key: query_key)
        return card.config unless definition

        definition.body.merge(card.config.except("query_key"))
      end

      def window_start(config)
        seconds = config["window_seconds"].to_i
        Time.current - seconds.seconds if seconds.positive?
      end

      def parse_time(value)
        Time.zone.parse(value) if value.present?
      rescue ArgumentError
        nil
      end
    end
  end
end
