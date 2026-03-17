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

  def root?
    path.root?
  end

  private

  attr_reader :source, :path
end
