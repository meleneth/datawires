# frozen_string_literal: true

require "forwardable"

class SchemaDocument
  extend Forwardable

  class NotASchemaDocumentError < ArgumentError; end

  attr_reader :document

  def_delegators :document, :id, :to_param, :key, :title, :domain, :head_revision, :body

  def initialize(document)
    @document = document
    raise NotASchemaDocumentError, "document is not a schema" unless document.schema?
  end

  def conforming_documents
    document.instance_documents.order(:title, :key)
  end

  def edit_affordances
    document.edit_affordances_for_schema.order(:title)
  end

  def view_affordances
    document.view_affordances_for_schema.order(:title)
  end

  def to_model
    document
  end
end
