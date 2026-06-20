# frozen_string_literal: true

module RetroUI
  module Rails
    class AccordionContentComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "pb-4 text-sm text-muted-foreground"

      def initialize(open: false, html_options: {})
        @open = open
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        data = (options.delete(:data) || options.delete("data") || {}).dup
        data[:retro_ui__accordion_target] = class_names(data[:retro_ui__accordion_target], "content")

        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:hidden] = true unless @open
        options[:data] = data
        options
      end
    end
  end
end
