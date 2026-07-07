# frozen_string_literal: true

module Clusters
  class SeedDomain
    DEFAULT_AFFORDANCE_TITLE = "Default"

    def self.call(domain:, cluster_key:, actor: nil)
      new(domain:, cluster_key:, actor:).call
    end

    def initialize(domain:, cluster_key:, actor:)
      raise ArgumentError, "domain must be a Domain" unless domain.is_a?(Domain)

      @domain = domain
      @cluster_key = cluster_key
      @actor = actor
    end

    def call
      definition = Clusters::Catalog.definition_for(cluster_key)
      return domain if definition.blank?

      ApplicationRecord.transaction do
        domain.update!(repository_mode: true) if definition.fetch(:repository_mode, false)

        definition.fetch(:schemas).each do |schema_definition|
          schema_document = ensure_document!(
            key: schema_definition.fetch(:key),
            title: schema_definition.fetch(:title),
            body: schema_definition.fetch(:body),
            schema_document: nil,
            message: "Seed #{definition.fetch(:name)} #{schema_definition.fetch(:title)} schema"
          )
          schema_wrapper = SyncSchemaWrapperForDocument.call(document: schema_document)
          schema_wrapper.update!(public: true) unless schema_wrapper.public?
          ensure_affordance!(
            schema_wrapper: schema_wrapper,
            schema_definition: schema_definition,
            cluster_name: definition.fetch(:name)
          )
          ensure_view_affordances!(
            schema_wrapper: schema_wrapper,
            schema_definition: schema_definition,
            cluster_name: definition.fetch(:name)
          )
        end
        ensure_home_document!(definition)
        create_initial_domain_commit!(definition) if definition.fetch(:repository_mode, false)

        domain
      end
    end

    private

    attr_reader :domain, :cluster_key, :actor

    def ensure_home_document!(definition)
      home_body = definition[:home]
      return if home_body.blank?
      existing_home = domain.documents.find_by(key: DomainHomeLinks::DOCUMENT_KEY)
      if existing_home
        attach_home_schema!(existing_home)
        return
      end

      ensure_document!(
        key: DomainHomeLinks::DOCUMENT_KEY,
        title: home_body.fetch("title", "#{definition.fetch(:name)} Home"),
        body: home_body,
        schema_document: home_schema_document,
        message: "Seed #{definition.fetch(:name)} domain home"
      )
    end

    def attach_home_schema!(home_document)
      schema_document = home_schema_document
      return unless schema_document

      home_document.update!(schema_document: schema_document) if home_document.schema_document != schema_document
    end

    def home_schema_document
      @home_schema_document ||= domain.documents.find_by(key: "domain-home-page")
    end

    def create_initial_domain_commit!(definition)
      return if domain.head_domain_commit.present?

      DomainCommits::Create.call(
        domain: domain,
        message: "Seed #{definition.fetch(:name)} cluster",
        actor: actor
      )
    end

    def ensure_affordance!(schema_wrapper:, schema_definition:, cluster_name:)
      affordance_document = ensure_document!(
        key: "#{schema_definition.fetch(:key)}-default-edit-affordance",
        title: "#{schema_definition.fetch(:title)} default edit affordance",
        body: schema_definition.fetch(:affordance),
        schema_document: nil,
        message: "Seed #{cluster_name} #{schema_definition.fetch(:title)} edit affordance"
      )

      affordance = schema_wrapper.edit_affordances.find_or_initialize_by(
        edit_document: affordance_document
      )
      affordance.title = DEFAULT_AFFORDANCE_TITLE
      affordance.public = true
      affordance.save!
    end

    def ensure_view_affordances!(schema_wrapper:, schema_definition:, cluster_name:)
      schema_definition.fetch(:view_affordances, []).each do |view_definition|
        affordance_document = ensure_document!(
          key: view_definition.fetch(:key),
          title: view_definition.fetch(:title),
          body: view_definition.fetch(:body),
          schema_document: nil,
          message: "Seed #{cluster_name} #{schema_definition.fetch(:title)} view affordance"
        )

        affordance = schema_wrapper.view_affordances.find_or_initialize_by(
          view_document: affordance_document
        )
        affordance.title = view_definition.fetch(:affordance_title)
        affordance.public = true
        affordance.save!
      end
    end

    def ensure_document!(key:, title:, body:, schema_document:, message:)
      document = domain.documents.find_or_initialize_by(key: key)
      document.title = title
      document.save! if document.new_record? || document.changed?

      if document.body != body
        revision = document.revisions.create!(
          body: body,
          parent_revision: document.head_revision,
          message: message,
          created_by: actor
        )
        document.update!(head_revision: revision)
      end

      document.update!(schema_document: schema_document) if document.schema_document != schema_document
      document
    end
  end
end
