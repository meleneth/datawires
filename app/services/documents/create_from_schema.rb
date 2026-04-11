# frozen_string_literal: true

module Documents
  class CreateFromSchema
    def self.call(schema_document:, actor: nil)
      new(schema_document:, actor:).call
    end

    def initialize(schema_document:, actor:)
      raise ArgumentError, "schema_document must be a SchemaDocument" unless schema_document.is_a?(SchemaDocument)

      @schema_document = schema_document
      @schema = schema_document.document
      @actor = actor
    end

    def call
      Document.transaction do
        document = Document.create!(
          domain: @schema.domain,
          schema_document: @schema,
          key: next_key
        )

        revision = document.revisions.create!(
          body: initial_body
        )

        document.update!(head_revision: revision)

        draft = document.draft_for(actor: @actor)

        [ document, draft ]
      end
    end

    private

    def next_key
      loop do
        key = "document-#{SecureRandom.hex(4)}"
        break key unless @schema.domain.documents.exists?(key: key)
      end
    end

    def initial_body
      {}
    end
  end
end
