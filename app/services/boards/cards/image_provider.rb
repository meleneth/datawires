# frozen_string_literal: true

module Boards
  module Cards
    class ImageProvider < BaseProvider
      class << self
        def validate(config, path: "config")
          errors = super
          return errors unless config.is_a?(Hash)

          errors << "#{path}.src must be a non-empty string" unless config["src"].to_s.present?
          errors << "#{path}.alt must be a non-empty string" unless config["alt"].to_s.present?
          errors
        end
      end

      def call
        Result.new(status: "available", title: card.title, description: card.description,
          data: card.config.slice("src", "alt", "caption"), href: nil, action_path: nil, action_method: nil,
          partial: "boards/cards/image")
      end
    end
  end
end
