# frozen_string_literal: true

module SchemaPaths
  class Inventory
    Entry = Struct.new(
      :cursor,
      :path,
      :ptr,
      :name,
      :label,
      :kind,
      :widget,
      :required,
      keyword_init: true
    ) do
      alias_method :required?, :required

      def object?
        kind == "object"
      end

      def array?
        kind == "array"
      end

      def scalar?
        kind == "scalar"
      end
    end

    attr_reader :root_cursor

    def initialize(root_cursor:)
      @root_cursor = root_cursor
    end

    def root_entries
      entries_for(root_cursor)
    end

    def entries_for(cursor)
      cursor.children.map { |child_cursor| entry_for(child_cursor) }
    end

    def entry_for(cursor)
      Entry.new(
        cursor: cursor,
        path: cursor.path,
        ptr: cursor.ptr,
        name: cursor.name,
        label: label_for(cursor),
        kind: kind_for(cursor),
        widget: widget_for(cursor),
        required: cursor.required?
      )
    end

    private

    def label_for(cursor)
      cursor.schema_node["title"].presence || cursor.name.to_s.humanize
    end

    def kind_for(cursor)
      return "object" if cursor.object?
      return "array" if cursor.array?

      "scalar"
    end

    def widget_for(cursor)
      return "array" if cursor.array?

      cursor.input_kind.to_s
    end
  end
end
