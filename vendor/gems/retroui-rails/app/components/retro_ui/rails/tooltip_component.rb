# frozen_string_literal: true

module RetroUI
  module Rails
    class TooltipComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "relative inline-block"

      def initialize(html_options: {})
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        data = (options.delete(:data) || options.delete("data") || {}).dup
        data[:controller] = class_names(data[:controller], "retro-ui--tooltip")

        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:data] = data
        options
      end
    end
  end
end
