# frozen_string_literal: true

module RetroUI
  module Rails
    class ButtonComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "font-head transition-all rounded outline-hidden cursor-pointer duration-200 font-medium inline-flex justify-center items-center disabled:opacity-60 disabled:cursor-not-allowed"
      PRESSABLE_CLASSES = "shadow-md hover:shadow active:shadow-none border-2 border-black hover:translate-y-1 active:translate-y-2 active:translate-x-1"

      VARIANTS = {
        default: "#{PRESSABLE_CLASSES} bg-primary text-primary-foreground",
        secondary: "#{PRESSABLE_CLASSES} bg-secondary text-secondary-foreground",
        outline: "#{PRESSABLE_CLASSES} bg-transparent",
        link: "bg-transparent hover:underline shadow-none border-0",
        ghost: "bg-transparent hover:bg-accent shadow-none border-0",
        destructive: "#{PRESSABLE_CLASSES} bg-destructive text-destructive-foreground"
      }.freeze

      SIZES = {
        sm: "h-8 px-3 text-sm",
        md: "h-10 px-4 py-2",
        lg: "h-12 px-6 text-lg",
        icon: "h-10 w-10 p-0"
      }.freeze

      attr_reader :label, :href

      def initialize(label: nil, href: nil, variant: :default, size: :md, html_options: {})
        @label = label
        @href = href
        @variant = variant.to_sym
        @size = size.to_sym
        @html_options = html_options.dup

        validate_option!(:variant, @variant, VARIANTS)
        validate_option!(:size, @size, SIZES)
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, VARIANTS.fetch(@variant), SIZES.fetch(@size), caller_classes)

        if href
          options[:href] = href
        else
          options[:type] ||= "button"
        end

        options
      end

      private

      def validate_option!(name, value, allowed)
        return if allowed.key?(value)

        raise ArgumentError, "Invalid #{name}: #{value.inspect}. Expected one of: #{allowed.keys.join(", ")}"
      end
    end
  end
end
