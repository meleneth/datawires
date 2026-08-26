# frozen_string_literal: true

module Boards
  module Cards
    class QueryProvider < ObservationProvider
      def call
        result = query_result
        Result.new(status: "available", title: card.title, description: card.description,
          data: { "query" => result }, href: nil, action_path: nil, action_method: nil,
          partial: "boards/cards/query")
      end
    end
  end
end
