# frozen_string_literal: true

module RetroUI
  module Rails
    class SeparatorComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      ORIENTATIONS = {
        horizontal: "w-full border-t-2 border-black",
        vertical: "min-h-6 border-l-2 border-black"
      }.freeze

      BASE_CLASSES = "shrink-0"

      def initialize(orientation: :horizontal, decorative: true, html_options: {})
        @orientation = orientation.to_sym
        @decorative = decorative
        @html_options = html_options.dup

        validate_orientation!
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, ORIENTATIONS.fetch(@orientation), caller_classes)
        options[:"aria-hidden"] = true if @decorative
        options[:role] ||= "separator" unless @decorative
        options[:"aria-orientation"] ||= @orientation unless @decorative
        options
      end

      private

      def validate_orientation!
        return if ORIENTATIONS.key?(@orientation)

        raise ArgumentError, "Invalid orientation: #{@orientation.inspect}. Expected one of: #{ORIENTATIONS.keys.join(", ")}"
      end
    end
  end
end
