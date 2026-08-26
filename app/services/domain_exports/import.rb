# frozen_string_literal: true

module DomainExports
  class Import
    def self.call(archive:, name: nil, owner: nil)
      new(archive:, name:, owner:).call
    end

    def initialize(archive:, name:, owner: nil)
      @archive = archive
      @name = name
      @owner = owner
    end

    def call
      validate_archive!

      ApplicationRecord.transaction do
        domain = create_domain!
        documents = create_documents!(domain)
        revisions = create_revisions!(documents)
        attach_document_heads!(documents, revisions)
        attach_schema_documents!(documents)
        schema_wrappers = create_schema_wrappers!(documents)
        create_edit_affordances!(schema_wrappers, documents)
        create_view_affordances!(schema_wrappers, documents)
        boards = create_boards!(schema_wrappers, documents)
        attach_default_boards!(schema_wrappers, boards)
        create_project_affordance!(domain, documents, boards)
        sources = create_sources!(domain, documents)
        create_metric_definitions!(domain, documents)
        source_runs = create_source_runs!(sources, revisions)
        create_observations!(domain, sources, source_runs, revisions)
        commits = create_domain_commits!(domain, documents, revisions)
        attach_domain_head!(domain, commits)
        domain
      end
    end

    private

    attr_reader :archive, :name, :owner

    def validate_archive!
      return if archive.is_a?(Hash) &&
                archive["format"] == DomainExports::Export::FORMAT &&
                [ 2, DomainExports::Export::VERSION ].include?(archive["version"])

      raise ArgumentError, "unsupported domain archive format"
    end

    def create_domain!
      payload = archive.fetch("domain")
      Domain.create!(
        name: name.presence || payload.fetch("name"),
        repository_mode: payload.fetch("repository_mode"),
        owner: owner,
        public: payload.fetch("public", false)
      )
    end

    def create_documents!(domain)
      archive.fetch("documents").each_with_object({}) do |payload, documents|
        documents[payload.fetch("ref")] = domain.documents.create!(
          key: payload["key"],
          title: payload["title"]
        )
      end
    end

    def create_revisions!(documents)
      archive.fetch("documents").each_with_object({}) do |document_payload, revisions|
        document = documents.fetch(document_payload.fetch("ref"))
        document_payload.fetch("revisions").each do |revision_payload|
          revisions[revision_payload.fetch("ref")] = document.revisions.create!(
            parent_revision: revisions[revision_payload["parent_revision_ref"]],
            message: revision_payload["message"],
            body: revision_payload.fetch("body")
          )
        end
      end
    end

    def attach_document_heads!(documents, revisions)
      archive.fetch("documents").each do |payload|
        documents.fetch(payload.fetch("ref")).update!(
          head_revision: revisions[payload["head_revision_ref"]]
        )
      end
    end

    def attach_schema_documents!(documents)
      archive.fetch("documents").each do |payload|
        documents.fetch(payload.fetch("ref")).update!(
          schema_document: documents[payload["schema_document_ref"]]
        )
      end
    end

    def create_schema_wrappers!(documents)
      archive.fetch("schema_wrappers").each_with_object({}) do |payload, wrappers|
        wrappers[payload.fetch("ref")] = SchemaWrapper.create!(
          document: documents.fetch(payload.fetch("document_ref"))
        )
      end
    end

    def create_edit_affordances!(schema_wrappers, documents)
      archive.fetch("edit_affordances").each do |payload|
        EditAffordance.create!(
          schema_wrapper: schema_wrappers.fetch(payload.fetch("schema_wrapper_ref")),
          edit_document: documents.fetch(payload.fetch("edit_document_ref")),
          title: payload.fetch("title")
        )
      end
    end

    def create_view_affordances!(schema_wrappers, documents)
      archive.fetch("view_affordances").each do |payload|
        ViewAffordance.create!(
          schema_wrapper: schema_wrappers.fetch(payload.fetch("schema_wrapper_ref")),
          view_document: documents.fetch(payload.fetch("view_document_ref")),
          title: payload.fetch("title")
        )
      end
    end

    def create_boards!(schema_wrappers, documents)
      archive.fetch("boards", []).each_with_object({}) do |payload, boards|
        boards[payload.fetch("ref")] = Board.create!(
          schema_wrapper: schema_wrappers.fetch(payload.fetch("schema_wrapper_ref")),
          board_document: documents.fetch(payload.fetch("board_document_ref")),
          title: payload.fetch("title"),
          public: payload.fetch("public", false)
        )
      end
    end

    def attach_default_boards!(schema_wrappers, boards)
      archive.fetch("schema_wrappers").each do |payload|
        default = boards[payload["default_board_ref"]]
        schema_wrappers.fetch(payload.fetch("ref")).update!(default_board: default) if default
      end
    end

    def create_project_affordance!(domain, documents, boards)
      payload = archive["project_affordance"]
      return unless payload

      ProjectAffordance.create!(domain:, project_document: documents.fetch(payload.fetch("project_document_ref")),
        default_board: boards[payload["default_board_ref"]])
    end

    def create_sources!(domain, documents)
      archive.fetch("sources", []).each_with_object({}) do |payload, sources|
        sources[payload.fetch("ref")] = Source.create!(
          domain:, source_document: documents.fetch(payload.fetch("source_document_ref")), enabled: payload.fetch("enabled", true),
          status: payload.fetch("status", "idle"), next_run_at: parse_time(payload["next_run_at"])
        )
      end
    end

    def create_metric_definitions!(domain, documents)
      archive.fetch("metric_definitions", []).each do |payload|
        MetricDefinition.create!(domain:, key: payload.fetch("key"),
          metric_document: documents.fetch(payload.fetch("metric_document_ref")))
      end
    end

    def create_source_runs!(sources, revisions)
      archive.fetch("source_runs", []).each_with_object({}) do |payload, runs|
        runs[payload.fetch("ref")] = SourceRun.create!(
          source: sources.fetch(payload.fetch("source_ref")),
          configuration_revision: revisions.fetch(payload.fetch("configuration_revision_ref")),
          trigger: payload.fetch("trigger"), adapter: payload.fetch("adapter"),
          adapter_version: payload.fetch("adapter_version"), status: payload.fetch("status"),
          attempt: payload.fetch("attempt", 1), idempotency_key: payload.fetch("idempotency_key"),
          started_at: parse_time(payload["started_at"]), finished_at: parse_time(payload["finished_at"]),
          observation_count: payload.fetch("observation_count", 0), error_class: payload["error_class"],
          error_message: payload["error_message"], metadata: payload.fetch("metadata", {})
        )
      end
    end

    def create_observations!(domain, sources, source_runs, revisions)
      observations = {}
      archive.fetch("observations", []).each do |payload|
        observations[payload.fetch("ref")] = Observation.create!(
          domain:, source: sources.fetch(payload.fetch("source_ref")), source_run: source_runs.fetch(payload.fetch("source_run_ref")),
          configuration_revision: revisions.fetch(payload.fetch("configuration_revision_ref")),
          corrects_observation: observations[payload["corrects_observation_ref"]],
          observation_type: payload.fetch("observation_type"), metric_key: payload["metric_key"], unit: payload["unit"],
          numeric_value: payload["numeric_value"], dimensions: payload.fetch("dimensions", {}), payload: payload.fetch("payload", {}),
          provenance: payload.fetch("provenance", {}), observed_at: parse_time(payload.fetch("observed_at")),
          effective_at: parse_time(payload.fetch("effective_at")), recorded_at: parse_time(payload.fetch("recorded_at")),
          correction_kind: payload["correction_kind"]
        )
      end
    end

    def parse_time(value)
      Time.zone.parse(value) if value.present?
    end

    def create_domain_commits!(domain, documents, revisions)
      archive.fetch("domain_commits").each_with_object({}) do |payload, commits|
        commit = domain.domain_commits.create!(
          parent_domain_commit: commits[payload["parent_domain_commit_ref"]],
          message: payload["message"],
          state_hash: payload.fetch("state_hash"),
          metadata: payload.fetch("metadata")
        )
        payload.fetch("documents").each do |entry_payload|
          commit.domain_commit_documents.create!(
            document: documents.fetch(entry_payload.fetch("document_ref")),
            revision: revisions.fetch(entry_payload.fetch("revision_ref")),
            document_key: entry_payload["document_key"],
            revision_hash: entry_payload.fetch("revision_hash")
          )
        end
        commits[payload.fetch("ref")] = commit
      end
    end

    def attach_domain_head!(domain, commits)
      domain.update!(head_domain_commit: commits[archive.fetch("domain")["head_domain_commit_ref"]])
    end
  end
end
