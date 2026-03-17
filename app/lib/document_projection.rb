# frozen_string_literal: true

class DocumentProjection
  def initialize(source:, path:)
    @source = source
    @path = path.is_a?(DocumentPath) ? path : DocumentPath.new(path)
  end

  def document_node
    JsonPtr.get(source.body, path.document_ptr)
  end

  def schema_node
    JsonPtr.get(source.schema_document.body, path.schema_ptr)
  end

  def schema_child_keys
    node = schema_node
    return [] unless node.is_a?(Hash)

    properties = node["properties"]
    return [] unless properties.is_a?(Hash)

    properties.keys.sort
  end

  def root?
    path.root?
  end

  private

  attr_reader :source, :path
end
