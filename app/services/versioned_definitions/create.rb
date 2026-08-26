# frozen_string_literal: true

module VersionedDefinitions
  class Create
    def self.call(domain:, actor:, schema:, key:, title:, body:, wrapper_class:, document_association:)
      new(domain:, actor:, schema:, key:, title:, body:, wrapper_class:, document_association:).call
    end

    def initialize(domain:, actor:, schema:, key:, title:, body:, wrapper_class:, document_association:)
      @domain = domain
      @actor = actor
      @schema = schema
      @key = key
      @title = title
      @body = body
      @wrapper_class = wrapper_class
      @document_association = document_association
    end

    def call
      ApplicationRecord.transaction do
        schema_document = ensure_schema
        document = domain.documents.create!(key: document_key, title:, schema_document: schema_document)
        revision = document.revisions.create!(body:, message: "Create #{title}", created_by: actor)
        document.update!(head_revision: revision)
        wrapper_class.create!(domain:, key:, document_association => document)
      end
    end

    private

    attr_reader :domain, :actor, :schema, :key, :title, :body, :wrapper_class, :document_association

    def ensure_schema
      document = domain.documents.find_or_initialize_by(key: schema::KEY)
      document.title = schema::TITLE
      document.save! if document.new_record? || document.changed?
      if document.body != schema::BODY
        revision = document.revisions.create!(body: schema::BODY, parent_revision: document.head_revision,
          message: "Install #{schema::TITLE} schema", created_by: actor)
        document.update!(head_revision: revision)
      end
      SyncSchemaWrapperForDocument.call(document:)
      document
    end

    def document_key
      base = "#{schema::KEY.delete_prefix('datawires-')}-#{key.parameterize}"
      candidate = base
      index = 2
      while domain.documents.exists?(key: candidate)
        candidate = "#{base}-#{index}"
        index += 1
      end
      candidate
    end
  end
end
