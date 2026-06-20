# frozen_string_literal: true

module RetroUI
  module Rails
    class DropdownMenuItemComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "block w-full rounded px-3 py-2 text-left text-sm transition-colors hover:bg-accent hover:text-accent-foreground"
      attr_reader :text, :href

      def initialize(text: nil, href: nil, html_options: {})
        @text = text
        @href = href
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:role] ||= "menuitem"
        href ? options.merge(href: href) : options.merge(type: (options[:type] || "button"))
      end
    end
  end
end
