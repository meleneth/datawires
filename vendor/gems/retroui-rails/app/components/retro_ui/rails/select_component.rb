# frozen_string_literal: true

module RetroUI
  module Rails
    class SelectComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "flex h-10 w-full cursor-pointer rounded border-2 border-black bg-background px-3 py-2 text-sm text-foreground shadow-sm transition-all focus-visible:outline-hidden focus-visible:shadow-md disabled:cursor-not-allowed disabled:opacity-60"

      attr_reader :options, :selected

      def initialize(name: nil, options: [], selected: nil, html_options: {})
        @name = name
        @options = options
        @selected = selected
        @html_options = html_options.dup
      end

      def component_options
        attrs = @html_options.dup
        caller_classes = attrs.delete(:class) || attrs.delete("class")
        attrs[:class] = class_names(BASE_CLASSES, caller_classes)
        attrs[:name] ||= @name if @name
        attrs
      end

      def option_pairs
        options.map do |option|
          option.is_a?(Array) ? option : [option, option]
        end
      end
    end
  end
end
