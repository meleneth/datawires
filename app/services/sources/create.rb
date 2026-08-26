# frozen_string_literal: true

module Sources
  class Create
    def self.call(domain:, title:, adapter:, config:, actor: nil, schedule: nil, observation: nil, credential: nil)
      new(domain:, title:, adapter:, config:, actor:, schedule:, observation:, credential:).call
    end

    def initialize(domain:, title:, adapter:, config:, actor:, schedule:, observation:, credential:)
      @domain = domain
      @title = title
      @adapter = adapter
      @config = config
      @actor = actor
      @schedule = schedule
      @observation = observation
      @credential = credential
    end

    def call
      ApplicationRecord.transaction do
        schema = ensure_schema
        document = domain.documents.create!(key: next_key, title:)
        body = { "version" => 1, "title" => title, "adapter" => adapter, "config" => config }
        body["schedule"] = schedule if schedule.present?
        body["observation"] = observation if observation.present?
        revision = document.revisions.create!(body:, message: "Create source", created_by: actor)
        document.update!(head_revision: revision, schema_document: schema)
        Source.create!(domain:, source_document: document, source_credential: credential,
          next_run_at: initial_next_run_at(body))
      end
    end

    private

    attr_reader :domain, :title, :adapter, :config, :actor, :schedule, :observation, :credential

    def ensure_schema
      document = domain.documents.find_or_initialize_by(key: Sources::Schema::KEY)
      document.title = Sources::Schema::TITLE
      document.save! if document.new_record? || document.changed?
      if document.body != Sources::Schema::BODY
        revision = document.revisions.create!(body: Sources::Schema::BODY, parent_revision: document.head_revision,
          message: "Install source schema", created_by: actor)
        document.update!(head_revision: revision)
      end
      SyncSchemaWrapperForDocument.call(document:)
      document
    end

    def next_key
      loop do
        key = "source-#{SecureRandom.hex(4)}"
        return key unless domain.documents.exists?(key:)
      end
    end

    def initial_next_run_at(body)
      Time.current if body.dig("schedule", "every_seconds")
    end
  end
end
