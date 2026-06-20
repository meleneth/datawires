# frozen_string_literal: true

module RetroUI
  module Rails
    class ProgressComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "relative h-4 w-full overflow-hidden rounded border-2 border-black bg-muted shadow-sm"
      INDICATOR_CLASSES = "h-full bg-primary transition-all"

      attr_reader :value, :max

      def initialize(value: 0, max: 100, html_options: {}, indicator_options: {})
        @value = value.to_f
        @max = max.to_f
        @html_options = html_options.dup
        @indicator_options = indicator_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:role] ||= "progressbar"
        options[:"aria-valuemin"] ||= 0
        options[:"aria-valuemax"] ||= max
        options[:"aria-valuenow"] ||= clamped_value
        options
      end

      def indicator_component_options
        options = @indicator_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        existing_style = options.delete(:style) || options.delete("style")
        options[:class] = class_names(INDICATOR_CLASSES, caller_classes)
        options[:style] = class_names("width: #{percentage}%;", existing_style)
        options
      end

      def clamped_value
        [[value, 0].max, max].min
      end

      def percentage
        return 0 if max <= 0

        ((clamped_value / max) * 100).round(2)
      end
    end
  end
end
