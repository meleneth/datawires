# frozen_string_literal: true

module RetroUI
  module Rails
    class ToastCloseComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "absolute right-2 top-2 inline-flex h-6 w-6 items-center justify-center rounded border-2 border-black bg-background text-sm font-medium text-foreground shadow-xs transition-all hover:translate-y-0.5 hover:shadow-none"

      attr_reader :label

      def initialize(label: "x", html_options: {})
        @label = label
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        data = (options.delete(:data) || options.delete("data") || {}).dup
        data[:action] = class_names(data[:action], "click->retro-ui--toast#dismiss")

        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:type] ||= "button"
        options[:"aria-label"] ||= "Dismiss"
        options[:data] = data
        options
      end
    end
  end
end
