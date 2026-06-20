# frozen_string_literal: true

module RetroUI
  module Rails
    class DialogContentComponent < ViewComponent::Base
      include RetroUI::Rails::ClassNames

      BACKDROP_CLASSES = "fixed inset-0 z-50 grid place-items-center bg-black/40 p-4"
      PANEL_CLASSES = "relative w-full max-w-lg rounded border-2 border-black bg-card p-6 text-card-foreground shadow-xl"

      def initialize(open: false, html_options: {})
        @open = open
        @html_options = html_options.dup
      end

      def wrapper_options
        data = { retro_ui__dialog_target: "panel", action: "click->retro-ui--dialog#backdropClose" }
        { class: BACKDROP_CLASSES, hidden: !@open, data: data }
      end

      def panel_options
        options = @html_options.dup
        caller_classes = options.delete(:class) || options.delete("class")
        options[:class] = class_names(PANEL_CLASSES, caller_classes)
        options[:role] ||= "dialog"
        options[:"aria-modal"] = true
        options
      end
    end
  end
end
