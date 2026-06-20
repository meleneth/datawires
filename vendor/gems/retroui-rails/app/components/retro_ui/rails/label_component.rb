# frozen_string_literal: true

module RetroUI
  module Rails
    class LabelComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "font-head text-sm font-medium leading-none text-foreground peer-disabled:cursor-not-allowed peer-disabled:opacity-60"

      attr_reader :text

      def initialize(text: nil, for_id: nil, html_options: {})
        @text = text
        @for_id = for_id
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:for] ||= @for_id if @for_id
        options
      end
    end
  end
end
