# frozen_string_literal: true

module RetroUI
  module Rails
    class TabsComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "w-full"

      def initialize(default_value: nil, html_options: {})
        @default_value = default_value
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        data = (options.delete(:data) || options.delete("data") || {}).dup
        data[:controller] = class_names(data[:controller], "retro-ui--tabs")
        data[:retro_ui__tabs_default_value_value] = @default_value if @default_value

        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:data] = data
        options
      end
    end
  end
end
