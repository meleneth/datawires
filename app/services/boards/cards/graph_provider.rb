# frozen_string_literal: true

module Boards
  module Cards
    class GraphProvider < ObservationProvider
      class << self
        def validate(config, path: "config")
          errors = super
          return errors unless config.is_a?(Hash)

          renderer = config.fetch("renderer", "line")
          errors << "#{path}.renderer is not registered: #{renderer}" unless Datawires::Providers.renderers.fetch(renderer)
          errors
        end
      end

      def call
        result = query_result
        renderer_name = card.config.fetch("renderer", "line")
        renderer = Datawires::Providers.renderers.fetch(renderer_name)
        return unavailable("Renderer #{renderer_name} is not registered.") unless renderer

        Result.new(status: "available", title: card.title, description: card.description,
          data: renderer.project(result:, config: card.config), href: nil, action_path: nil, action_method: nil,
          partial: renderer.partial)
      end
    end
  end
end
