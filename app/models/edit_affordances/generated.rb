# frozen_string_literal: true

module EditAffordances
  class Generated
    DEFAULT_FIELD_SPAN = 4

    attr_reader :schema_wrapper

    def initialize(schema_wrapper:)
      raise ArgumentError, "schema_wrapper must be a SchemaWrapper" unless schema_wrapper.is_a?(SchemaWrapper)

      @schema_wrapper = schema_wrapper
    end

    def id
      nil
    end

    def title
      "Generated"
    end

    def body
      {}
    end

    def column_count
      12
    end

    def projected_rows(root_cursor)
      object_rows = []
      scalar_fields = []

      root_cursor.children.each do |child_cursor|
        if child_cursor.object?
          object_rows << build_section_row(child_cursor)
          object_rows.concat(build_field_rows(child_cursor.children))
        else
          scalar_fields << build_field_cell(child_cursor)
        end
      end

      grouped_rows(scalar_fields) + object_rows
    end

    private

    def build_section_row(cursor)
      EditAffordances::ProjectedRow.new(
        cells: [
          EditAffordances::ProjectedField.new(
            cursor: cursor,
            span: column_count,
            widget: "section",
            label: true
          )
        ],
        column_count: column_count
      )
    end

    def build_field_rows(cursors)
      grouped_rows(cursors.map { |cursor| build_field_cell(cursor) })
    end

    def build_field_cell(cursor)
      EditAffordances::ProjectedField.new(
        cursor: cursor,
        span: DEFAULT_FIELD_SPAN,
        widget: cursor.array? ? "array" : "auto",
        label: true
      )
    end

    def grouped_rows(cells)
      cells.each_slice(3).map do |cell_group|
        EditAffordances::ProjectedRow.new(
          cells: cell_group,
          column_count: column_count
        )
      end
    end
  end
end
