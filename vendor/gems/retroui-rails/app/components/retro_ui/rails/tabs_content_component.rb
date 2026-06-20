# frozen_string_literal: true

module RetroUI
  module Rails
    class TabsContentComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "mt-3 rounded border-2 border-black bg-card p-4 text-card-foreground shadow-md"

      def initialize(value:, active: false, html_options: {})
        @value = value
        @active = active
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        data = (options.delete(:data) || options.delete("data") || {}).dup
        data[:retro_ui__tabs_target] = class_names(data[:retro_ui__tabs_target], "content")
        data[:retro_ui__tabs_value] = @value

        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:role] ||= "tabpanel"
        options[:hidden] = true unless @active
        options[:data] = data
        options
      end
    end
  end
end
