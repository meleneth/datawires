# frozen_string_literal: true

module DomainExports
  class Import
    def self.call(archive:, name: nil)
      new(archive:, name:).call
    end

    def initialize(archive:, name:)
      @archive = archive
      @name = name
    end

    def call
      validate_archive!

      ApplicationRecord.transaction do
        domain = create_domain!
        documents = create_documents!(domain)
        revisions = create_revisions!(documents)
        attach_document_links!(documents, revisions)
        schema_wrappers = create_schema_wrappers!(documents)
        create_edit_affordances!(schema_wrappers, documents)
        create_view_affordances!(schema_wrappers, documents)
        commits = create_domain_commits!(domain, documents, revisions)
        attach_domain_head!(domain, commits)
        domain
      end
    end

    private

    attr_reader :archive, :name

    def validate_archive!
      return if archive.is_a?(Hash) &&
                archive["format"] == DomainExports::Export::FORMAT &&
                archive["version"] == DomainExports::Export::VERSION

      raise ArgumentError, "unsupported domain archive format"
    end

    def create_domain!
      payload = archive.fetch("domain")
      Domain.create!(
        name: name.presence || payload.fetch("name"),
        repository_mode: payload.fetch("repository_mode")
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

    def attach_document_links!(documents, revisions)
      archive.fetch("documents").each do |payload|
        documents.fetch(payload.fetch("ref")).update!(
          schema_document: documents[payload["schema_document_ref"]],
          head_revision: revisions[payload["head_revision_ref"]]
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
