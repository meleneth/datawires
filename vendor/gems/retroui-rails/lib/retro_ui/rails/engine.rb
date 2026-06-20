# frozen_string_literal: true

require "rails/engine"
require "view_component"

module RetroUI
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace RetroUI::Rails

      config.autoload_paths << root.join("app/components").to_s
      config.eager_load_paths << root.join("app/components").to_s

      initializer "retroui_rails.assets" do |app|
        if app.config.respond_to?(:assets)
          app.config.assets.paths << root.join("app/javascript").to_s
          app.config.assets.precompile += %w[
            retro_ui/rails/theme.css
            retro_ui/rails/controllers/toast_controller.js
            retro_ui/rails/controllers/accordion_controller.js
            retro_ui/rails/controllers/chart_controller.js
            retro_ui/rails/controllers/tabs_controller.js
            retro_ui/rails/controllers/dialog_controller.js
            retro_ui/rails/controllers/dropdown_menu_controller.js
            retro_ui/rails/controllers/popover_controller.js
            retro_ui/rails/controllers/tooltip_controller.js
          ]
        end
      end
    end
  end
end
