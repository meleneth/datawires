# frozen_string_literal: true

module EditAffordances
  class ProjectedRow
    attr_reader :cells, :column_count

    def initialize(cells:, column_count:)
      @cells = cells
      @column_count = column_count
    end

    def empty?
      cells.empty?
    end

    def grid_class
      "grid-cols-#{column_count}"
    end
  end
end
