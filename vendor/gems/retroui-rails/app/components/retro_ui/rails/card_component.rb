# frozen_string_literal: true

module RetroUI
  module Rails
    class CardComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "inline-block border-2 rounded shadow-md transition-all hover:shadow-none bg-card text-card-foreground"

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
