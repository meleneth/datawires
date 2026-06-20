# frozen_string_literal: true

require "retro_ui/rails"

Rails.application.config.to_prepare do
  RetroUI::Rails.constants.grep(/Component\z/).each do |constant_name|
    next if Object.const_defined?(constant_name, false)

    Object.const_set(constant_name, RetroUI::Rails.const_get(constant_name))
  end
end
