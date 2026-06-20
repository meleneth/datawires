# frozen_string_literal: true

module RetroUI
  module Rails
    class AspectRatioComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "relative w-full overflow-hidden"

      def initialize(ratio: "16/9", html_options: {})
        @ratio = ratio
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        existing_style = options.delete(:style) || options.delete("style")
        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:style] = class_names("aspect-ratio: #{@ratio};", existing_style)
        options
      end
    end
  end
end
