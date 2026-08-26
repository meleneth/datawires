# frozen_string_literal: true

module Sources
  module Adapters
    class DerivedMetric
      VERSION = "1"

      def self.validate(config, path: "config")
        return [ "#{path} must be an object" ] unless config.is_a?(Hash)
        return [] if config["metric_key"].to_s.present?

        [ "#{path}.metric_key must be a non-empty string" ]
      end

      def initialize(configuration:, credential: nil)
      end

      def call
        raise NotImplementedError, "derived metrics are materialized by Metrics::Rollup"
      end
    end
  end
end
