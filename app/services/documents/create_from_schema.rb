# frozen_string_literal: true

module Documents
  class CreateFromSchema
    def self.call(schema_wrapper:, actor: nil, initial_values: {})
      new(schema_wrapper:, actor:, initial_values:).call
    end

    def initialize(schema_wrapper:, actor:, initial_values:)
      raise ArgumentError, "schema_wrapper must be a SchemaWrapper" unless schema_wrapper.is_a?(SchemaWrapper)

      @schema_wrapper = schema_wrapper
      @schema = schema_wrapper.document
      @actor = actor
      raise ArgumentError, "initial_values must be an object" unless initial_values.is_a?(Hash)
      @initial_values = initial_values.deep_dup
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
      @initial_values.deep_dup
    end
  end
end
