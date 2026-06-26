# frozen_string_literal: true

module DomainExports
  class Export
    FORMAT = "datawires.domain.archive"
    VERSION = 1

    def self.call(domain:)
      new(domain:).call
    end

    def initialize(domain:)
      raise ArgumentError, "domain must be a Domain" unless domain.is_a?(Domain)

      @domain = domain
    end

    def call
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

    attr_reader :domain

    def domain_payload
      {
        "id" => domain.id,
        "name" => domain.name,
        "repository_mode" => domain.repository_mode?,
        "head_domain_commit_id" => domain.head_domain_commit_id
      }
    end

    def documents_payload
      domain.documents.includes(:revisions).order(:key, :id).map do |document|
        {
          "id" => document.id,
          "key" => document.key,
          "title" => document.title,
          "schema_document_id" => document.schema_document_id,
          "head_revision_id" => document.head_revision_id,
          "revisions" => document.revisions.map do |revision|
            {
              "id" => revision.id,
              "parent_revision_id" => revision.parent_revision_id,
              "created_by_id" => revision.created_by_id,
              "message" => revision.message,
              "body" => revision.body
            }
          end
        }
      end
    end

    def schema_wrappers_payload
      SchemaWrapper.joins(:document)
        .where(documents: { domain_id: domain.id })
        .order(:document_id)
        .map do |wrapper|
          {
            "id" => wrapper.id,
            "document_id" => wrapper.document_id
          }
        end
    end

    def edit_affordances_payload
      EditAffordance.joins(schema_wrapper: :document)
        .where(documents: { domain_id: domain.id })
        .order(:schema_wrapper_id, :title)
        .map do |affordance|
          {
            "id" => affordance.id,
            "schema_wrapper_id" => affordance.schema_wrapper_id,
            "edit_document_id" => affordance.edit_document_id,
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
            "id" => affordance.id,
            "schema_wrapper_id" => affordance.schema_wrapper_id,
            "view_document_id" => affordance.view_document_id,
            "title" => affordance.title
          }
        end
    end

    def domain_commits_payload
      domain.domain_commits.includes(:domain_commit_documents).order(:created_at, :id).map do |commit|
        {
          "id" => commit.id,
          "parent_domain_commit_id" => commit.parent_domain_commit_id,
          "created_by_id" => commit.created_by_id,
          "message" => commit.message,
          "state_hash" => commit.state_hash,
          "metadata" => commit.metadata,
          "documents" => commit.domain_commit_documents.order(:document_key, :document_id).map do |entry|
            {
              "id" => entry.id,
              "document_id" => entry.document_id,
              "revision_id" => entry.revision_id,
              "document_key" => entry.document_key,
              "revision_hash" => entry.revision_hash
            }
          end
        }
      end
    end
  end
end
