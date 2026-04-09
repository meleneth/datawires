# frozen_string_literal: true

module Editors
  class Row
    GRID_CLASSES = {
      1 => "grid-cols-1",
      2 => "grid-cols-2",
      3 => "grid-cols-3",
      4 => "grid-cols-4",
      5 => "grid-cols-5",
      6 => "grid-cols-6",
      7 => "grid-cols-7",
      8 => "grid-cols-8",
      9 => "grid-cols-9",
      10 => "grid-cols-10",
      11 => "grid-cols-11",
      12 => "grid-cols-12"
    }.freeze

    attr_reader :cells, :column_count

    def initialize(cells:, column_count: 12)
      @cells = cells
      @column_count = column_count.to_i
    end

    def grid_class
      GRID_CLASSES.fetch(column_count, "grid-cols-12")
    end
  end
end
