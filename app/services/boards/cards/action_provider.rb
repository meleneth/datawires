# frozen_string_literal: true

module Boards
  module Cards
    class ActionProvider < BaseProvider
      include Rails.application.routes.url_helpers

      class << self
        def validate(config, path: "config")
          errors = super
          errors << "#{path}.action_id must be a non-empty string" unless config.is_a?(Hash) && config["action_id"].to_s.present?
          errors
        end
      end

      def call
        action = board.projection.actions.find { |candidate| candidate.id == card.config["action_id"] }
        return unavailable("Board action #{card.config['action_id']} was not found.") unless action

        resolution = Boards::ActionResolution.call(board:, action:, actor:)
        return unavailable(resolution.reason) unless resolution.available?

        path = resolution.domain_command ? board_action_form_path(board, action.id) : board_action_path(board, action.id)
        Result.new(status: "available", title: card.title, description: card.description, data: {}, href: nil,
          action_path: path, action_method: resolution.domain_command ? :get : :post)
      end
    end
  end
end
