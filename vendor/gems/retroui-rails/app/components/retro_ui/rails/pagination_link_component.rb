# frozen_string_literal: true

module RetroUI
  module Rails
    class PaginationLinkComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "font-head inline-flex h-9 min-w-9 items-center justify-center rounded border-2 border-black px-3 text-sm font-medium shadow-sm transition-all hover:translate-y-0.5 hover:shadow-none"
      ACTIVE_CLASSES = "bg-primary text-primary-foreground"
      INACTIVE_CLASSES = "bg-background text-foreground"

      attr_reader :href, :label

      def initialize(href:, label: nil, active: false, html_options: {})
        @href = href
        @label = label
        @active = active
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, @active ? ACTIVE_CLASSES : INACTIVE_CLASSES, caller_classes)
        options[:href] ||= href
        options[:"aria-current"] ||= "page" if @active
        options
      end
    end
  end
end
