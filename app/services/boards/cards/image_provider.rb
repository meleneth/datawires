# frozen_string_literal: true

module Boards
  module Cards
    class ImageProvider < BaseProvider
      include Rails.application.routes.url_helpers

      class << self
        def validate(config, path: "config")
          errors = super
          return errors unless config.is_a?(Hash)

          errors << "#{path}.document_key must be a non-empty string" unless config["document_key"].to_s.present?
          errors
        end
      end

      def call
        document = board.schema_wrapper.domain.documents.includes(:head_revision).find_by(key: card.config["document_key"])
        return unavailable("Image document #{card.config['document_key']} was not found.") unless document

        Result.new(status: "available", title: card.title, description: card.description,
          data: { "src" => document_image_path(document), "alt" => document.body["alt"].presence || card.title,
                  "caption" => card.config["caption"].presence || document.body["caption"] },
          href: nil, action_path: nil, action_method: nil,
          partial: "boards/cards/image")
      end
    end
  end
end
