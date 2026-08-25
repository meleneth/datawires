# frozen_string_literal: true

module Projects
  class Install
    def self.call(domain:, actor: nil, title: nil, description: nil)
      new(domain:, actor:, title:, description:).call
    end

    def initialize(domain:, actor:, title:, description:)
      @domain = domain
      @actor = actor
      @title = title
      @description = description
    end

    def call
      ApplicationRecord.transaction do
        return domain.project_affordance if domain.project_affordance

        schema = ensure_schema
        document = ensure_project_document(schema)
        ProjectAffordance.create!(domain:, project_document: document)
      end
    end

    private

    attr_reader :domain, :actor, :title, :description

    def ensure_schema
      document = domain.documents.find_or_initialize_by(key: ProjectAffordances::Schema::KEY)
      document.title = ProjectAffordances::Schema::TITLE
      document.save! if document.new_record? || document.changed?
      if document.body != ProjectAffordances::Schema::BODY
        revision = document.revisions.create!(body: ProjectAffordances::Schema::BODY, parent_revision: document.head_revision,
          message: "Install project affordance schema", created_by: actor)
        document.update!(head_revision: revision)
      end
      SyncSchemaWrapperForDocument.call(document:)
      document
    end

    def ensure_project_document(schema)
      document = domain.documents.find_or_initialize_by(key: "project-affordance")
      document.title = title.presence || document.title.presence || "#{domain.name} Project"
      document.save! if document.new_record? || document.changed?
      body = initial_body
      if document.head_revision.nil? || document.body != body
        revision = document.revisions.create!(body:, parent_revision: document.head_revision,
          message: "Install project affordance", created_by: actor)
        document.update!(head_revision: revision)
      end
      document.update!(schema_document: schema) if document.schema_document != schema
      document
    end

    def initial_body
      {
        "version" => 1,
        "title" => title.presence || domain.name,
        "description" => description.to_s,
        "groups" => [ { "title" => "Project", "links" => [] } ]
      }
    end
  end
end
