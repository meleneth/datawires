# frozen_string_literal: true

module Documents
  class CreateFromSchema
    def self.call(schema:, actor: nil)
      new(schema:, actor:).call
    end

    def initialize(schema:, actor:)
      raise ArgumentError, "schema must be a schema document" unless schema.schema_document?

      @schema = schema
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
        break key unless @schema.domain.documents.exists?(key:)
      end
    end

    def initial_body
      {}
    end
  end
end
