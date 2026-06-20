# frozen_string_literal: true

module RetroUI
  module Rails
    class ToastComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "relative grid w-full gap-1 rounded border-2 border-black bg-card p-4 pr-10 text-card-foreground shadow-md transition-all duration-200 data-[state=closed]:translate-x-2 data-[state=closed]:opacity-0"

      VARIANTS = {
        default: "",
        destructive: "bg-destructive text-destructive-foreground"
      }.freeze

      attr_reader :duration

      def initialize(variant: :default, duration: 0, html_options: {})
        @variant = variant.to_sym
        @duration = duration.to_i
        @html_options = html_options.dup

        validate_variant!
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        data = (options.delete(:data) || options.delete("data") || {}).dup
        data[:controller] = class_names(data[:controller], "retro-ui--toast")
        data[:retro_ui__toast_duration_value] = duration
        data[:state] ||= "open"

        options[:class] = class_names(BASE_CLASSES, VARIANTS.fetch(@variant), caller_classes)
        options[:role] ||= @variant == :destructive ? "alert" : "status"
        options[:data] = data
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
