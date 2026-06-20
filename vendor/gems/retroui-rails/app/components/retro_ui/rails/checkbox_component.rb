# frozen_string_literal: true

module RetroUI
  module Rails
    class CheckboxComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "peer h-5 w-5 shrink-0 cursor-pointer rounded border-2 border-black bg-background text-primary shadow-sm accent-primary transition-all focus-visible:outline-hidden focus-visible:shadow-md disabled:cursor-not-allowed disabled:opacity-60"

      def initialize(name: nil, value: "1", checked: false, html_options: {})
        @name = name
        @value = value
        @checked = checked
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:type] ||= "checkbox"
        options[:name] ||= @name if @name
        options[:value] ||= @value if @value
        options[:checked] = true if @checked
        options
      end
    end
  end
end
