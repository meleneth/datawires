module Navigation
  # frozen_string_literal: true

  class NavMenuComponent < ViewComponent::Base
    renders_many :entries
    attr_reader :title, :align, :width_class

    def initialize(title:, align: :left, width_class: "w-56")
      @title = title
      @align = align
      @width_class = width_class
    end

    def panel_align_class
      case align.to_sym
      when :right then "right-0 origin-top-right"
      else "left-0 origin-top-left"
      end
    end
  end
end
