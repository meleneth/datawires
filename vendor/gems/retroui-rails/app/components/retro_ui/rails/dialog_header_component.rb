# frozen_string_literal: true

module RetroUI
  module Rails
    class DialogHeaderComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "grid gap-1.5 pr-8"

      def initialize(html_options: {})
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
