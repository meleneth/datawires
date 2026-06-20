# frozen_string_literal: true

module RetroUI
  module Rails
    class PaginationComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "mx-auto flex w-full justify-center"

      def initialize(label: "Pagination", html_options: {})
        @label = label
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:"aria-label"] ||= @label
        options
      end
    end
  end
end
