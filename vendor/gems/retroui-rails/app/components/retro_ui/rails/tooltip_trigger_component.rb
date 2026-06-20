# frozen_string_literal: true

module RetroUI
  module Rails
    class TooltipTriggerComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "underline decoration-2 underline-offset-4"
      attr_reader :text

      def initialize(text: nil, html_options: {})
        @text = text
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        data = (options.delete(:data) || options.delete("data") || {}).dup
        data[:action] = class_names(data[:action], "mouseenter->retro-ui--tooltip#show mouseleave->retro-ui--tooltip#hide focus->retro-ui--tooltip#show blur->retro-ui--tooltip#hide")

        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:tabindex] ||= 0
        options[:data] = data
        options
      end
    end
  end
end
