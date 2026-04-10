# frozen_string_literal: true

module Documents
  class Projection
    attr_reader :source, :path, :edit_affordance

    def initialize(source:, path:, edit_affordance: nil)
      @source = source
      @path = path.is_a?(Documents::Path) ? path : Documents::Path.new(path)
      @edit_affordance = edit_affordance
    end

    def root?
      path.root?
    end

    def editor_column_count
      count = edit_affordance&.dig("screen", "columns")
      count.present? ? count.to_i : 12
    end

    def document_node
      JsonPtr.get(source.body, path.document_ptr)
    end

    def schema_node
      JsonPtr.get(source.schema_document.body, path.schema_ptr)
    end

    def schema_child_keys
      properties = schema_node.is_a?(Hash) ? schema_node["properties"] : nil
      return [] unless properties.is_a?(Hash)

      properties.keys.sort
    end

    def child_property_names
      schema_child_keys
    end

    def child_schema(name)
      JsonPtr.get(source.schema_document.body, path.child(name).schema_ptr) || {}
    end

    def child_value(name)
      node = document_node
      return nil unless node.is_a?(Hash)

      return node[name] if node.key?(name)
      return node[name.to_sym] if node.key?(name.to_sym)

      nil
    end

    def child_present?(name)
      node = document_node
      node.is_a?(Hash) && (node.key?(name) || node.key?(name.to_sym))
    end

    def child_required?(name)
      node = schema_node
      Array(node.is_a?(Hash) ? node["required"] : nil).include?(name)
    end

    def editor_rows
      return affordance_editor_rows if edit_affordance.present?

      default_editor_rows
    end

    def child_rows
      default_child_rows
    end

    def default_child_rows
      child_property_names.map do |name|
        Documents::ProjectionRow.new(
          projection: self,
          path: path.child(name)
        )
      end
    end

    private

    def default_editor_rows
      default_child_rows.map do |row|
        Editors::Row.new(
          cells: [
            Editors::FieldCell.new(
              projection_row: row,
              span: nil,
              widget: "auto",
              label: true
            )
          ],
          column_count: editor_column_count
        )
      end
    end

    def affordance_editor_rows
      Array(edit_affordance["rows"]).map do |row|
        Editors::Row.new(
          cells: Array(row).map { |cell| build_affordance_cell(cell) }.compact,
          column_count: editor_column_count
        )
      end.reject { |row| row.cells.empty? }
    end

    def build_affordance_cell(cell)
      return build_commit_cell(cell) if commit_cell?(cell)
      return build_field_cell(cell) if field_cell?(cell)

      raise ArgumentError, "unsupported edit affordance cell: #{cell.inspect}"
    end

    def build_commit_cell(cell)
      Editors::CommitCell.new(
        span: cell["span"],
        message_mode: cell["message_mode"] || "hidden"
      )
    end

    def build_field_cell(cell)
      projection_row = projection_row_for_binding(cell.fetch("binding"))
      return nil unless projection_row

      Editors::FieldCell.new(
        projection_row: projection_row,
        span: cell["span"],
        widget: cell["widget"] || "auto",
        label: cell.key?("label") ? cell["label"] : true
      )
    end

    def commit_cell?(cell)
      cell.is_a?(Hash) && cell["kind"] == "commit"
    end

    def field_cell?(cell)
      cell.is_a?(Hash) && cell.key?("binding")
    end

    def projection_row_for_binding(binding_data)
      binding = EditForms::Binding.new(binding_data)

      case binding.kind
      when "document_ptr"
        projection_row_for_ptr(binding.document_ptr)
      else
        raise ArgumentError, "unsupported binding kind: #{binding.kind.inspect}"
      end
    end

    def projection_row_for_ptr(ptr)
      pointer = JsonPtr::Pointer.parse(ptr)
      document_ptr = pointer.to_s

      return nil unless within_projection_root?(document_ptr)

      relative_tokens = relative_tokens_for(document_ptr)
      return nil if relative_tokens.empty?

      row_path = relative_tokens.reduce(path) { |current, token| current.child(token) }

      Documents::ProjectionRow.new(projection: self, path: row_path)
    rescue ArgumentError
      nil
    end

    def within_projection_root?(document_ptr)
      root_tokens = JsonPtr::Pointer.parse(path.document_ptr).tokens.map(&:unescaped)
      target_tokens = JsonPtr::Pointer.parse(document_ptr).tokens.map(&:unescaped)

      target_tokens.first(root_tokens.length) == root_tokens
    end

    def relative_tokens_for(document_ptr)
      root_tokens = JsonPtr::Pointer.parse(path.document_ptr).tokens.map(&:unescaped)
      target_tokens = JsonPtr::Pointer.parse(document_ptr).tokens.map(&:unescaped)

      target_tokens.drop(root_tokens.length)
    end
  end
end
