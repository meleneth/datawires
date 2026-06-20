# frozen_string_literal: true

module RetroUI
  module Rails
    class KbdComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "font-head inline-flex min-h-6 items-center rounded border-2 border-black bg-background px-1.5 text-xs font-medium shadow-xs"

      attr_reader :text

      def initialize(text: nil, html_options: {})
        @text = text
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options
      end
    end
  end
end
