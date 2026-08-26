# frozen_string_literal: true

module Boards
  module Cards
    class FormProvider < BaseProvider
      include Rails.application.routes.url_helpers

      class << self
        def validate(config, path: "config")
          errors = super
          errors << "#{path}.schema_key must be a non-empty string" unless config.is_a?(Hash) && config["schema_key"].to_s.present?
          errors
        end
      end

      def call
        schema = board.schema_wrapper.domain.documents.find_by(key: card.config["schema_key"])
        return unavailable("Schema #{card.config['schema_key']} was not found.") unless schema&.schema_wrapper

        Result.new(status: "available", title: card.title, description: card.description,
          data: { "schema_wrapper" => schema.schema_wrapper }, href: nil,
          action_path: schema_documents_path(schema.schema_wrapper), action_method: :post, partial: nil)
      end
    end
  end
end
