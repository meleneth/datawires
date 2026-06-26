# frozen_string_literal: true

module DomainExports
  class Export
    FORMAT = "datawires.domain.archive"
    VERSION = 2

    def self.call(domain:)
      new(domain:).call
    end

    def initialize(domain:)
      raise ArgumentError, "domain must be a Domain" unless domain.is_a?(Domain)

      @domain = domain
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
        "domain_commits" => domain_commits_payload
      }
    end

    private

    attr_reader :domain, :document_refs, :revision_refs, :schema_wrapper_refs, :domain_commit_refs

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
    end

    def domain_payload
      {
        "name" => domain.name,
        "repository_mode" => domain.repository_mode?,
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
          "document_ref" => document_refs.fetch(wrapper.document_id)
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
  end
end
