# frozen_string_literal: true

module Boards
  module Cards
    class MetricProvider < ObservationProvider
      def call
        result = query_result
        statistic = card.config.fetch("statistic", "last")
        Result.new(status: "available", title: card.title, description: card.description,
          data: { "value" => result.statistics[statistic], "statistic" => statistic, "lineage" => result.lineage },
          href: nil, action_path: nil, action_method: nil, partial: "boards/cards/metric")
      end
    end
  end
end
