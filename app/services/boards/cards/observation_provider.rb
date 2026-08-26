# frozen_string_literal: true

module Boards
  module Cards
    class ObservationProvider < BaseProvider
      class << self
        def validate(config, path: "config")
          errors = super
          errors << "#{path}.metric_key must be a non-empty string" unless config.is_a?(Hash) && config["metric_key"].to_s.present?
          errors
        end
      end

      private

      def query_result
        Observations::Query.call(
          domain: board.schema_wrapper.domain,
          metric_key: card.config["metric_key"],
          source_id: card.config["source_id"],
          dimensions: card.config["dimensions"] || {},
          from: parse_time(card.config["from"]),
          to: parse_time(card.config["to"]),
          bucket_seconds: card.config["bucket_seconds"],
          aggregate: card.config.fetch("aggregate", "average")
        )
      end

      def parse_time(value)
        Time.zone.parse(value) if value.present?
      rescue ArgumentError
        nil
      end
    end
  end
end
