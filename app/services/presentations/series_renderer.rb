# frozen_string_literal: true

module Presentations
  class SeriesRenderer
    class << self
      def partial
        "boards/cards/series"
      end

      def project(result:, config:)
        {
          "renderer" => config.fetch("renderer", "line"),
          "points" => result.points.map { |point| { "time" => point.time.iso8601, "value" => point.value } },
          "statistics" => result.statistics,
          "lineage" => result.lineage,
          "unit" => config["unit"].to_s
        }
      end
    end
  end
end
