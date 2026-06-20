# frozen_string_literal: true

module RetroUI
  module Rails
    class ToastViewportComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "fixed bottom-4 right-4 z-50 flex w-full max-w-sm flex-col gap-3"

      def initialize(html_options: {})
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:"aria-live"] ||= "polite"
        options
      end
    end
  end
end
