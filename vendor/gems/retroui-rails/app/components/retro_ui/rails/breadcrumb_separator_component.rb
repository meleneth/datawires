# frozen_string_literal: true

module RetroUI
  module Rails
    class BreadcrumbSeparatorComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "select-none text-foreground"

      attr_reader :separator

      def initialize(separator: "/", html_options: {})
        @separator = separator
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:"aria-hidden"] = true
        options
      end
    end
  end
end
