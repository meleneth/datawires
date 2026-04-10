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

    def resolved_path(path = self.path)
      Documents::ResolvedPath.new(
        path: path,
        schema_body: source.schema_document.body
      )
    end

    def schema_node
      resolved_path.schema_node
    end

    def schema_child_keys
      properties = schema_node.is_a?(Hash) ? schema_node["properties"] : nil
      return [] unless properties.is_a?(Hash)

      properties.keys.sort
    end

    def child_property_names
      schema_child_keys
    end

    def editor_rows
      return affordance_editor_rows if edit_affordance.present?

      default_editor_rows
    end

    def child_rows
      default_child_rows
    end

    def default_child_rows
      case resolved_path.schema_type
      when "object"
        object_child_rows
      when "array"
        array_child_rows
      else
        []
      end
    end

    private

    def object_child_rows
      child_property_names.map do |name|
        Documents::ProjectionRow.new(
          projection: self,
          path: path.child(name)
        )
      end
    end

    def array_child_rows
      Array(document_node).each_index.map do |index|
        Documents::ProjectionRow.new(
          projection: self,
          path: path.child(index.to_s)
        )
      end
    end

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
      candidate_path = Documents::Path.new(ptr)
      return nil unless within_projection_root?(candidate_path)

      Documents::ProjectionRow.new(
        projection: self,
        path: candidate_path
      )
    rescue Documents::Path::InvalidPathError,
           Documents::ResolvedPath::InvalidTraversalError,
           ArgumentError
      nil
    end

    def within_projection_root?(candidate_path)
      root_tokens = path.tokens
      candidate_tokens = candidate_path.tokens

      return false unless candidate_tokens.first(root_tokens.length) == root_tokens

      resolved_path(candidate_path)
      true
    rescue Documents::ResolvedPath::InvalidTraversalError
      false
    end
  end
end
