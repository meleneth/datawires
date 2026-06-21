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
      inventory = SchemaPaths::Inventory.new(root_cursor: root_cursor)

      inventory.root_entries.each do |entry|
        if entry.object?
          object_rows << build_section_row(entry.cursor)
          object_rows.concat(build_field_rows(inventory.entries_for(entry.cursor)))
        else
          scalar_fields << build_field_cell(entry)
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

    def build_field_rows(entries)
      grouped_rows(entries.map { |entry| build_field_cell(entry) })
    end

    def build_field_cell(entry)
      EditAffordances::ProjectedField.new(
        cursor: entry.cursor,
        span: DEFAULT_FIELD_SPAN,
        widget: entry.widget == "array" ? "array" : "auto",
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
