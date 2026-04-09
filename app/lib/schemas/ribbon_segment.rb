module Schemas
  # frozen_string_literal: true

  class RibbonSegment
    attr_reader :label, :path, :url, :menu_items

    def initialize(label:, path:, url:, current:, menu_items:)
      @label = label
      @path = path
      @url = url
      @current = current
      @menu_items = menu_items
    end

    def current?
      @current
    end
  end
end
