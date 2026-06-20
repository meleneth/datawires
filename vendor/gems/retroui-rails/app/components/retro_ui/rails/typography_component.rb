# frozen_string_literal: true

module RetroUI
  module Rails
    class TypographyComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      ELEMENTS = {
        h1: "h1",
        h2: "h2",
        h3: "h3",
        h4: "h4",
        p: "p",
        blockquote: "blockquote",
        lead: "p",
        small: "small",
        muted: "p"
      }.freeze

      CLASSES = {
        h1: "font-head text-4xl font-medium tracking-normal text-foreground",
        h2: "font-head text-3xl font-medium tracking-normal text-foreground",
        h3: "font-head text-2xl font-medium tracking-normal text-foreground",
        h4: "font-head text-xl font-medium tracking-normal text-foreground",
        p: "leading-7 text-foreground",
        blockquote: "border-l-4 border-black pl-4 italic text-foreground",
        lead: "text-xl text-muted-foreground",
        small: "text-sm font-medium leading-none",
        muted: "text-sm text-muted-foreground"
      }.freeze

      attr_reader :text

      def initialize(as: :p, text: nil, html_options: {})
        @as = as.to_sym
        @text = text
        @html_options = html_options.dup

        validate_element!
      end

      def call
        tag.public_send(ELEMENTS.fetch(@as), **component_options) do
          content? ? content : text
        end
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(CLASSES.fetch(@as), caller_classes)
        options
      end

      private

      def validate_element!
        return if ELEMENTS.key?(@as)

        raise ArgumentError, "Invalid typography element: #{@as.inspect}. Expected one of: #{ELEMENTS.keys.join(", ")}"
      end
    end
  end
end
