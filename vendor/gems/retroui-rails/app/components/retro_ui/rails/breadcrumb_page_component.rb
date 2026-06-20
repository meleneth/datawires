# frozen_string_literal: true

module RetroUI
  module Rails
    class BreadcrumbPageComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "font-medium text-foreground"

      attr_reader :text

      def initialize(text: nil, html_options: {})
        @text = text
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:"aria-current"] ||= "page"
        options
      end
    end
  end
end
