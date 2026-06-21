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

    def projection(root_cursor)
      object_rows = []
      scalar_fields = []
      inventory = SchemaPaths::Inventory.new(root_cursor: root_cursor)

      inventory.root_entries.each do |entry|
        if entry.object?
          object_rows << build_section_row(entry.cursor)
          object_rows.concat(build_field_rows(inventory.entries_for(entry.cursor)))
        else
          scalar_fields << build_field_cell(entry)
        end
      end

      EditAffordances::Projection.new(
        rows: grouped_rows(scalar_fields) + object_rows,
        defaults: EditAffordances::Projection::Defaults.new(column_count: column_count)
      )
    end

    def projected_rows(root_cursor)
      projection(root_cursor).rows
    end

    private

    def build_section_row(cursor)
      EditAffordances::ProjectedRow.new(
        cells: [
          EditAffordances::Cells::Section.new(
            cursor: cursor,
            span: column_count,
            label: true
          )
        ],
        column_count: column_count
      )
    end

    def build_field_rows(entries)
      grouped_rows(entries.map { |entry| build_field_cell(entry) })
    end

    def build_field_cell(entry)
      cell_class = entry.widget == "array" ? EditAffordances::Cells::Array : EditAffordances::Cells::Field

      cell_args = {
        cursor: entry.cursor,
        span: DEFAULT_FIELD_SPAN,
        widget: entry.widget == "array" ? "array" : "auto",
        label: true
      }
      cell_args[:collection] = EditAffordances::Collection.default if cell_class == EditAffordances::Cells::Array

      cell_class.new(**cell_args)
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
