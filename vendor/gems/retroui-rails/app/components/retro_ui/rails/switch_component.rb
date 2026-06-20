# frozen_string_literal: true

module RetroUI
  module Rails
    class SwitchComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "peer h-6 w-11 cursor-pointer appearance-none rounded-full border-2 border-black bg-muted shadow-sm transition-all checked:bg-primary focus-visible:outline-hidden focus-visible:shadow-md disabled:cursor-not-allowed disabled:opacity-60"

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
        options[:role] ||= "switch"
        options[:name] ||= @name if @name
        options[:value] ||= @value if @value
        options[:checked] = true if @checked
        options[:"aria-checked"] ||= @checked
        options
      end
    end
  end
end
