# frozen_string_literal: true

module RetroUI
  module Rails
    class AccordionTriggerComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "font-head flex w-full items-center justify-between py-4 text-left font-medium transition-all hover:underline"

      attr_reader :text

      def initialize(text: nil, expanded: false, html_options: {})
        @text = text
        @expanded = expanded
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        data = (options.delete(:data) || options.delete("data") || {}).dup
        data[:retro_ui__accordion_target] = class_names(data[:retro_ui__accordion_target], "trigger")
        data[:action] = class_names(data[:action], "click->retro-ui--accordion#toggle")

        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:type] ||= "button"
        options[:"aria-expanded"] = @expanded
        options[:data] = data
        options
      end
    end
  end
end
