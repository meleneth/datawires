# frozen_string_literal: true

module EditAffordances
  class Generated
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
      root_cursor.children.map do |child_cursor|
        EditAffordances::ProjectedRow.new(
          cells: [
            EditAffordances::ProjectedField.new(
              cursor: child_cursor,
              span: nil,
              widget: "auto",
              label: true
            )
          ],
          column_count: column_count
        )
      end
    end
  end
end
