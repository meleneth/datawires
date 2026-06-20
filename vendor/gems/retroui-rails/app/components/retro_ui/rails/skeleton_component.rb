# frozen_string_literal: true

module RetroUI
  module Rails
    class SkeletonComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "animate-pulse rounded border-2 border-black bg-muted shadow-sm"

      def initialize(html_options: {})
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
