# frozen_string_literal: true

module RetroUI
  module Rails
    class BadgeComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "font-head inline-flex items-center rounded border-2 border-black px-2.5 py-0.5 text-xs font-medium shadow-sm transition-all"

      VARIANTS = {
        default: "bg-primary text-primary-foreground",
        secondary: "bg-secondary text-secondary-foreground",
        outline: "bg-transparent text-foreground",
        destructive: "bg-destructive text-destructive-foreground"
      }.freeze

      attr_reader :label

      def initialize(label: nil, variant: :default, html_options: {})
        @label = label
        @variant = variant.to_sym
        @html_options = html_options.dup

        validate_variant!
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, VARIANTS.fetch(@variant), caller_classes)
        options
      end

      private

      def validate_variant!
        return if VARIANTS.key?(@variant)

        raise ArgumentError, "Invalid variant: #{@variant.inspect}. Expected one of: #{VARIANTS.keys.join(", ")}"
      end
    end
  end
end
