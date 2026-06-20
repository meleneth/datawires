# frozen_string_literal: true

module RetroUI
  module Rails
    class DialogTriggerComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BASE_CLASSES = "font-head transition-all rounded outline-hidden cursor-pointer duration-200 font-medium inline-flex justify-center items-center disabled:opacity-60 disabled:cursor-not-allowed shadow-md hover:shadow active:shadow-none border-2 border-black hover:translate-y-1 active:translate-y-2 active:translate-x-1 bg-primary text-primary-foreground h-10 px-4 py-2"

      attr_reader :label

      def initialize(label: nil, html_options: {})
        @label = label
        @html_options = html_options.dup
      end

      def component_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        data = (options.delete(:data) || options.delete("data") || {}).dup
        data[:action] = class_names(data[:action], "click->retro-ui--dialog#open")

        options[:class] = class_names(BASE_CLASSES, caller_classes)
        options[:type] ||= "button"
        options[:data] = data
        options
      end
    end
  end
end
