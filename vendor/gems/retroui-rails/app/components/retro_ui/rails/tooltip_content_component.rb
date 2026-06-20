# frozen_string_literal: true

module RetroUI
  module Rails
    class TooltipContentComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "absolute bottom-full left-1/2 z-40 mb-2 -translate-x-1/2 whitespace-nowrap rounded border-2 border-black bg-foreground px-2 py-1 text-xs text-background shadow-sm"
      attr_reader :text

      def initialize(text: nil, open: false, html_options: {})
        @text = text
        @open = open
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        data = (options.delete(:data) || options.delete("data") || {}).dup
        data[:retro_ui__tooltip_target] = class_names(data[:retro_ui__tooltip_target], "content")

        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:role] ||= "tooltip"
        options[:hidden] = true unless @open
        options[:data] = data
        options
      end
    end
  end
end
