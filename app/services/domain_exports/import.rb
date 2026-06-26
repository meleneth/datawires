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
        id: payload.fetch("id"),
        name: name.presence || payload.fetch("name"),
        repository_mode: payload.fetch("repository_mode")
      )
    end

    def create_documents!(domain)
      archive.fetch("documents").each_with_object({}) do |payload, documents|
        document = domain.documents.create!(
          id: payload.fetch("id"),
          key: payload["key"],
          title: payload["title"]
        )
        documents[document.id] = document
      end
    end

    def create_revisions!(documents)
      archive.fetch("documents").each_with_object({}) do |document_payload, revisions|
        document = documents.fetch(document_payload.fetch("id"))
        document_payload.fetch("revisions").each do |revision_payload|
          revision = document.revisions.create!(
            id: revision_payload.fetch("id"),
            parent_revision: revisions[revision_payload["parent_revision_id"]],
            created_by_id: existing_user_id(revision_payload["created_by_id"]),
            message: revision_payload["message"],
            body: revision_payload.fetch("body")
          )
          revisions[revision.id] = revision
        end
      end
    end

    def attach_document_links!(documents, revisions)
      archive.fetch("documents").each do |payload|
        document = documents.fetch(payload.fetch("id"))
        document.update!(
          schema_document: documents[payload["schema_document_id"]],
          head_revision: revisions[payload["head_revision_id"]]
        )
      end
    end

    def create_schema_wrappers!(documents)
      archive.fetch("schema_wrappers").each_with_object({}) do |payload, wrappers|
        wrapper = SchemaWrapper.create!(
          id: payload.fetch("id"),
          document: documents.fetch(payload.fetch("document_id"))
        )
        wrappers[wrapper.id] = wrapper
      end
    end

    def create_edit_affordances!(schema_wrappers, documents)
      archive.fetch("edit_affordances").each do |payload|
        EditAffordance.create!(
          id: payload.fetch("id"),
          schema_wrapper: schema_wrappers.fetch(payload.fetch("schema_wrapper_id")),
          edit_document: documents.fetch(payload.fetch("edit_document_id")),
          title: payload.fetch("title")
        )
      end
    end

    def create_view_affordances!(schema_wrappers, documents)
      archive.fetch("view_affordances").each do |payload|
        ViewAffordance.create!(
          id: payload.fetch("id"),
          schema_wrapper: schema_wrappers.fetch(payload.fetch("schema_wrapper_id")),
          view_document: documents.fetch(payload.fetch("view_document_id")),
          title: payload.fetch("title")
        )
      end
    end

    def create_domain_commits!(domain, documents, revisions)
      archive.fetch("domain_commits").each_with_object({}) do |payload, commits|
        commit = domain.domain_commits.create!(
          id: payload.fetch("id"),
          parent_domain_commit: commits[payload["parent_domain_commit_id"]],
          created_by_id: existing_user_id(payload["created_by_id"]),
          message: payload["message"],
          state_hash: payload.fetch("state_hash"),
          metadata: payload.fetch("metadata")
        )
        payload.fetch("documents").each do |entry_payload|
          commit.domain_commit_documents.create!(
            id: entry_payload.fetch("id"),
            document: documents.fetch(entry_payload.fetch("document_id")),
            revision: revisions.fetch(entry_payload.fetch("revision_id")),
            document_key: entry_payload["document_key"],
            revision_hash: entry_payload.fetch("revision_hash")
          )
        end
        commits[commit.id] = commit
      end
    end

    def attach_domain_head!(domain, commits)
      domain.update!(head_domain_commit: commits[archive.fetch("domain")["head_domain_commit_id"]])
    end

    def existing_user_id(user_id)
      return nil if user_id.blank?
      return user_id if User.exists?(user_id)

      nil
    end
  end
end
