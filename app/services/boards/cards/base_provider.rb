# frozen_string_literal: true

module Boards
  module Cards
    class BaseProvider
      class << self
        def validate(config, path: "config")
          config.is_a?(Hash) ? [] : [ "#{path} must be an object" ]
        end
      end

      def initialize(board:, card:, actor:)
        @board = board
        @card = card
        @actor = actor
      end

      private

      attr_reader :board, :card, :actor

      def unavailable(message)
        Result.new(status: "unavailable", title: card.title, description: message, data: {}, href: nil,
          action_path: nil, action_method: nil)
      end
    end
  end
end
