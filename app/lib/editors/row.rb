module Editors
  # frozen_string_literal: true

  class Row
    attr_reader :cells

    def initialize(cells:)
      @cells = cells
    end
  end
end
