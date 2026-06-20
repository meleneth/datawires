# frozen_string_literal: true

module RetroUI
  module Rails
    class BreadcrumbLinkComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "transition-colors hover:text-foreground hover:underline"

      attr_reader :href, :text

      def initialize(href:, text: nil, html_options: {})
        @href = href
        @text = text
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:href] ||= href
        options
      end
    end
  end
end
