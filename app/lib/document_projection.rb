# app/lib/document_projection.rb
# frozen_string_literal: true

class DocumentProjection
  attr_reader :source, :path

  def initialize(source:, path:)
    @source = source
    @path = path.is_a?(DocumentPath) ? path : DocumentPath.new(path)
  end

  def root?
    path.root?
  end

  def document_node
    JsonPtr.get(@source.body, path.document_ptr)
  end

  def schema_node
    JsonPtr.get(@source.schema_document.body, path.schema_ptr)
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
    JsonPtr.get(@source.schema_document.body, path.child(name).schema_ptr) || {}
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

  def child_rows
    child_property_names.map do |name|
      DocumentProjectionRow.new(projection: self, name:)
    end
  end
end
