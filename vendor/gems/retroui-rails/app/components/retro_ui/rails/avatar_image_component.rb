# frozen_string_literal: true

module RetroUI
  module Rails
    class AvatarImageComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "aspect-square h-full w-full object-cover"

      def initialize(src:, alt: "", html_options: {})
        @src = src
        @alt = alt
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:src] ||= @src
        options[:alt] ||= @alt
        options
      end
    end
  end
end
