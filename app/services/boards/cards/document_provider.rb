# frozen_string_literal: true

module Boards
  module Cards
    class DocumentProvider < BaseProvider
      include Rails.application.routes.url_helpers

      class << self
        def validate(config, path: "config")
          errors = super
          errors << "#{path}.document_key must be a non-empty string" unless config.is_a?(Hash) && config["document_key"].to_s.present?
          errors
        end
      end

      def call
        document = board.schema_wrapper.domain.documents.includes(:head_revision).find_by(key: card.config["document_key"])
        return unavailable("Document #{card.config['document_key']} was not found.") unless document

        view = selected_view(document)
        href = view ? document_view_affordance_path(document, view) : document_path(document)
        Result.new(status: "available", title: card.title.presence || document.title.presence || document.key,
          description: card.description, data: { "document" => document }, href:, action_path: nil, action_method: nil,
          partial: nil)
      end

      private

      def selected_view(document)
        title = card.config["view_affordance"]
        return unless title.present?

        document.schema_record&.view_affordances&.find_by(title:)
      end
    end
  end
end
