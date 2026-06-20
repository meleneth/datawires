# frozen_string_literal: true

require "retro_ui/rails/erb_compat"
require "rails"
require "action_controller/railtie"
require "action_view/railtie"

require "retro_ui/rails"

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.secret_key_base = "test"
    config.hosts.clear
  end
end
