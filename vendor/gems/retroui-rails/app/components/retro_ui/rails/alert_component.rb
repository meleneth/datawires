# frozen_string_literal: true

module RetroUI
  module Rails
    class AlertComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "relative w-full rounded border-2 border-black p-4 shadow-md bg-card text-card-foreground"

      VARIANTS = {
        default: "",
        destructive: "bg-destructive text-destructive-foreground"
      }.freeze

      def initialize(variant: :default, html_options: {})
        @variant = variant.to_sym
        @html_options = html_options.dup

        validate_variant!
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, VARIANTS.fetch(@variant), caller_classes)
        options[:role] ||= @variant == :destructive ? "alert" : "status"
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
