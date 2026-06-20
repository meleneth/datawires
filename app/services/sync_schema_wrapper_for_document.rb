# frozen_string_literal: true

class SyncSchemaWrapperForDocument
  def self.call(document:)
    new(document:).call
  end

  def initialize(document:)
    raise ArgumentError, "document must be a Document" unless document.is_a?(Document)

    @document = document
  end

  def call
    if document.supported_schema?
      document.schema_wrapper || document.create_schema_wrapper!
    else
      clear_dependent_schema_references!
      document.schema_wrapper&.destroy!
      nil
    end
  end

  private

  attr_reader :document

  def clear_dependent_schema_references!
    document.instance_documents.update_all(
      schema_document_id: nil,
      updated_at: Time.current
    )
  end
end
