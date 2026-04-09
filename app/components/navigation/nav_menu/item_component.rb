module Navigation
  module NavMenu
    # frozen_string_literal: true

    class ItemComponent < ViewComponent::Base
      attr_reader :title, :href, :method, :icon, :active

      def initialize(title:, href:, method: nil, icon: nil, active: false)
        @title = title
        @href = href
        @method = method
        @icon = icon
        @active = active
      end

      def item_classes
        base = "block rounded-lg px-3 py-2 hover:by-slate-800/70 hover:text-white"
        return base unless active
        "#{base} bg-slate-800/60 text-white"
      end
    end
  end
end
