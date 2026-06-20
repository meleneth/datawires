# frozen_string_literal: true

module RetroUI
  module Rails
    class TabsTriggerComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "font-head inline-flex h-9 items-center justify-center rounded px-3 text-sm font-medium transition-all data-[state=active]:border-2 data-[state=active]:border-black data-[state=active]:bg-background data-[state=active]:shadow-xs"

      attr_reader :text

      def initialize(value:, text: nil, active: false, html_options: {})
        @value = value
        @text = text
        @active = active
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        data = (options.delete(:data) || options.delete("data") || {}).dup
        data[:retro_ui__tabs_target] = class_names(data[:retro_ui__tabs_target], "trigger")
        data[:retro_ui__tabs_value_param] = @value
        data[:action] = class_names(data[:action], "click->retro-ui--tabs#select")
        data[:state] = @active ? "active" : "inactive"

        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:type] ||= "button"
        options[:role] ||= "tab"
        options[:"aria-selected"] = @active
        options[:data] = data
        options
      end
    end
  end
end
