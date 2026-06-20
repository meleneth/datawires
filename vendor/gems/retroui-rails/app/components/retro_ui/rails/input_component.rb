# frozen_string_literal: true

module RetroUI
  module Rails
    class InputComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "flex h-10 w-full rounded border-2 border-black bg-background px-3 py-2 text-sm text-foreground shadow-sm transition-all placeholder:text-muted-foreground focus-visible:outline-hidden focus-visible:shadow-md disabled:cursor-not-allowed disabled:opacity-60"

      def initialize(type: :text, name: nil, value: nil, html_options: {})
        @type = type
        @name = name
        @value = value
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:type] ||= @type
        options[:name] ||= @name if @name
        options[:value] ||= @value if @value
        options
      end
    end
  end
end
