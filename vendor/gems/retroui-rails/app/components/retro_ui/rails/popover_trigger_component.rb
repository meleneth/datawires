# frozen_string_literal: true

module RetroUI
  module Rails
    class PopoverTriggerComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "font-head inline-flex h-10 items-center justify-center rounded border-2 border-black bg-secondary px-4 py-2 font-medium text-secondary-foreground shadow-md transition-all hover:translate-y-1 hover:shadow"
      attr_reader :label

      def initialize(label: nil, html_options: {})
        @label = label
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        data = (options.delete(:data) || options.delete("data") || {}).dup
        data[:action] = class_names(data[:action], "click->retro-ui--popover#toggle")

        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:type] ||= "button"
        options[:"aria-expanded"] ||= false
        options[:data] = data
        options
      end
    end
  end
end
