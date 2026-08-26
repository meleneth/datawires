# frozen_string_literal: true

module DomainExports
  class Export
    FORMAT = "datawires.domain.archive"
    VERSION = 4

    def self.call(domain:, include_operational_history: true)
      new(domain:, include_operational_history:).call
    end

    def initialize(domain:, include_operational_history:)
      raise ArgumentError, "domain must be a Domain" unless domain.is_a?(Domain)

      @domain = domain
      @include_operational_history = include_operational_history
    end

    def call
      build_refs

      {
        "format" => FORMAT,
        "version" => VERSION,
        "domain" => domain_payload,
        "documents" => documents_payload,
        "schema_wrappers" => schema_wrappers_payload,
        "edit_affordances" => edit_affordances_payload,
        "view_affordances" => view_affordances_payload,
        "boards" => boards_payload,
        "project_affordance" => project_affordance_payload,
        "sources" => sources_payload,
        "metric_definitions" => metric_definitions_payload,
        "query_definitions" => query_definitions_payload,
        "source_runs" => source_runs_payload,
        "observations" => observations_payload,
        "credential_requirements" => domain.source_credentials.order(:name).pluck(:name),
        "domain_commits" => domain_commits_payload,
        "extensions" => extension_payloads
      }
    end

    private

    attr_reader :domain, :include_operational_history, :document_refs, :revision_refs, :schema_wrapper_refs, :domain_commit_refs,
      :board_refs, :source_refs, :source_run_refs, :observation_refs

    def build_refs
      @document_refs = ordered_documents.each_with_index.to_h do |document, index|
        [ document.id, "document-#{index + 1}" ]
      end
      @revision_refs = ordered_revisions.each_with_index.to_h do |revision, index|
        [ revision.id, "revision-#{index + 1}" ]
      end
      @schema_wrapper_refs = ordered_schema_wrappers.each_with_index.to_h do |wrapper, index|
        [ wrapper.id, "schema-wrapper-#{index + 1}" ]
      end
      @domain_commit_refs = ordered_domain_commits.each_with_index.to_h do |commit, index|
        [ commit.id, "commit-#{index + 1}" ]
      end
      @board_refs = boards.each_with_index.to_h { |board, index| [ board.id, "board-#{index + 1}" ] }
      @source_refs = domain.sources.order(:created_at, :id).each_with_index.to_h { |source, index| [ source.id, "source-#{index + 1}" ] }
      runs = include_operational_history ? SourceRun.where(source_id: source_refs.keys).order(:created_at, :id) : SourceRun.none
      @source_run_refs = runs.each_with_index.to_h do |run, index|
        [ run.id, "source-run-#{index + 1}" ]
      end
      observations = include_operational_history ? domain.observations.order(:recorded_at, :id) : Observation.none
      @observation_refs = observations.each_with_index.to_h do |observation, index|
        [ observation.id, "observation-#{index + 1}" ]
      end
    end

    def domain_payload
      {
        "name" => domain.name,
        "repository_mode" => domain.repository_mode?,
        "public" => domain.public?,
        "head_domain_commit_ref" => domain_commit_refs[domain.head_domain_commit_id]
      }
    end

    def documents_payload
      ordered_documents.map do |document|
        {
          "ref" => document_refs.fetch(document.id),
          "key" => document.key,
          "title" => document.title,
          "schema_document_ref" => document_refs[document.schema_document_id],
          "head_revision_ref" => revision_refs[document.head_revision_id],
          "revisions" => document.revisions.map do |revision|
            {
              "ref" => revision_refs.fetch(revision.id),
              "parent_revision_ref" => revision_refs[revision.parent_revision_id],
              "message" => revision.message,
              "body" => revision.body
            }
          end
        }
      end
    end

    def schema_wrappers_payload
      ordered_schema_wrappers.map do |wrapper|
        {
          "ref" => schema_wrapper_refs.fetch(wrapper.id),
          "document_ref" => document_refs.fetch(wrapper.document_id),
          "default_board_ref" => board_refs[wrapper.default_board_id]
        }
      end
    end

    def edit_affordances_payload
      EditAffordance.joins(schema_wrapper: :document)
        .where(documents: { domain_id: domain.id })
        .order(:schema_wrapper_id, :title)
        .map do |affordance|
          {
            "schema_wrapper_ref" => schema_wrapper_refs.fetch(affordance.schema_wrapper_id),
            "edit_document_ref" => document_refs.fetch(affordance.edit_document_id),
            "title" => affordance.title
          }
        end
    end

    def view_affordances_payload
      ViewAffordance.joins(schema_wrapper: :document)
        .where(documents: { domain_id: domain.id })
        .order(:schema_wrapper_id, :title)
        .map do |affordance|
          {
            "schema_wrapper_ref" => schema_wrapper_refs.fetch(affordance.schema_wrapper_id),
            "view_document_ref" => document_refs.fetch(affordance.view_document_id),
            "title" => affordance.title
          }
        end
    end

    def boards_payload
      boards.map do |board|
        {
          "ref" => board_refs.fetch(board.id),
          "schema_wrapper_ref" => schema_wrapper_refs.fetch(board.schema_wrapper_id),
          "board_document_ref" => document_refs.fetch(board.board_document_id),
          "title" => board.title,
          "public" => board.public?
        }
      end
    end

    def project_affordance_payload
      project = domain.project_affordance
      return unless project

      {
        "project_document_ref" => document_refs.fetch(project.project_document_id),
        "default_board_ref" => board_refs[project.default_board_id]
      }
    end

    def sources_payload
      domain.sources.order(:created_at, :id).map do |source|
        {
          "ref" => source_refs.fetch(source.id),
          "source_document_ref" => document_refs.fetch(source.source_document_id),
          "credential_name" => source.source_credential&.name,
          "enabled" => source.enabled?,
          "status" => source.status,
          "next_run_at" => source.next_run_at&.iso8601
        }
      end
    end

    def metric_definitions_payload
      domain.metric_definitions.order(:key).map do |metric|
        { "key" => metric.key, "metric_document_ref" => document_refs.fetch(metric.metric_document_id) }
      end
    end

    def query_definitions_payload
      domain.query_definitions.order(:key).map do |query|
        { "key" => query.key, "query_document_ref" => document_refs.fetch(query.query_document_id) }
      end
    end

    def source_runs_payload
      return [] unless include_operational_history

      SourceRun.where(source_id: source_refs.keys).order(:created_at, :id).map do |run|
        {
          "ref" => source_run_refs.fetch(run.id), "source_ref" => source_refs.fetch(run.source_id),
          "configuration_revision_ref" => revision_refs.fetch(run.configuration_revision_id), "trigger" => run.trigger,
          "adapter" => run.adapter, "adapter_version" => run.adapter_version, "status" => run.status,
          "attempt" => run.attempt, "idempotency_key" => run.idempotency_key, "started_at" => run.started_at&.iso8601,
          "finished_at" => run.finished_at&.iso8601, "observation_count" => run.observation_count,
          "error_class" => run.error_class, "error_message" => run.error_message, "metadata" => run.metadata
        }
      end
    end

    def observations_payload
      return [] unless include_operational_history

      domain.observations.order(:recorded_at, :id).map do |observation|
        {
          "ref" => observation_refs.fetch(observation.id), "source_ref" => source_refs.fetch(observation.source_id),
          "source_run_ref" => source_run_refs.fetch(observation.source_run_id),
          "configuration_revision_ref" => revision_refs.fetch(observation.configuration_revision_id),
          "corrects_observation_ref" => observation_refs[observation.corrects_observation_id],
          "observation_type" => observation.observation_type, "metric_key" => observation.metric_key,
          "unit" => observation.unit, "numeric_value" => observation.numeric_value&.to_s,
          "dimensions" => observation.dimensions, "payload" => observation.payload,
          "provenance" => observation.provenance.except("source_id", "source_document_id", "configuration_revision_id", "source_run_id").merge(
            "source_ref" => source_refs.fetch(observation.source_id),
            "source_document_ref" => document_refs.fetch(observation.source.source_document_id),
            "configuration_revision_ref" => revision_refs.fetch(observation.configuration_revision_id),
            "source_run_ref" => source_run_refs.fetch(observation.source_run_id)
          ), "observed_at" => observation.observed_at.iso8601,
          "effective_at" => observation.effective_at.iso8601, "recorded_at" => observation.recorded_at.iso8601,
          "correction_kind" => observation.correction_kind
        }
      end
    end

    def extension_payloads
      Datawires::Providers.archive_contributors.kinds.index_with do |kind|
        provider = Datawires::Providers.archive_contributors.fetch(kind)
        { "version" => provider::VERSION, "payload" => provider.export(domain:) }
      end
    end

    def domain_commits_payload
      ordered_domain_commits.map do |commit|
        {
          "ref" => domain_commit_refs.fetch(commit.id),
          "parent_domain_commit_ref" => domain_commit_refs[commit.parent_domain_commit_id],
          "message" => commit.message,
          "state_hash" => commit.state_hash,
          "metadata" => commit.metadata,
          "documents" => commit.domain_commit_documents.order(:document_key).map do |entry|
            {
              "document_ref" => document_refs.fetch(entry.document_id),
              "revision_ref" => revision_refs.fetch(entry.revision_id),
              "document_key" => entry.document_key,
              "revision_hash" => entry.revision_hash
            }
          end
        }
      end
    end

    def ordered_documents
      @ordered_documents ||= domain.documents.includes(:revisions).order(:key, :title, :created_at).to_a
    end

    def ordered_revisions
      @ordered_revisions ||= ordered_documents.flat_map(&:revisions)
    end

    def ordered_schema_wrappers
      @ordered_schema_wrappers ||= SchemaWrapper.joins(:document)
        .where(documents: { domain_id: domain.id })
        .order(:document_id)
        .to_a
    end

    def ordered_domain_commits
      @ordered_domain_commits ||= domain.domain_commits.includes(:domain_commit_documents).order(:created_at, :id).to_a
    end

    def boards
      @boards ||= Board.joins(schema_wrapper: :document).where(documents: { domain_id: domain.id }).order(:title, :id).to_a
    end
  end
end
