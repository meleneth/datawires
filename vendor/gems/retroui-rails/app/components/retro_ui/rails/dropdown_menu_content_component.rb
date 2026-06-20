# frozen_string_literal: true

module RetroUI
  module Rails
    class DropdownMenuContentComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "absolute right-0 z-40 mt-2 min-w-44 rounded border-2 border-black bg-card p-1 text-card-foreground shadow-md"

      def initialize(open: false, html_options: {})
        @open = open
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        data = (options.delete(:data) || options.delete("data") || {}).dup
        data[:retro_ui__dropdown_menu_target] = class_names(data[:retro_ui__dropdown_menu_target], "content")

        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:role] ||= "menu"
        options[:hidden] = true unless @open
        options[:data] = data
        options
      end
    end
  end
end
