# frozen_string_literal: true

require "digest"
require "json"

module DomainCommits
  class Create
    HASH_VERSION = 2

    def self.call(domain:, message:, actor: nil)
      new(domain:, message:, actor:).call
    end

    def initialize(domain:, message:, actor:)
      raise ArgumentError, "domain must be a Domain" unless domain.is_a?(Domain)

      @domain = domain
      @message = message
      @actor = actor
    end

    def call
      DomainCommit.transaction do
        domain.lock!
        parent = domain.head_domain_commit
        entries = document_entries
        commit = domain.domain_commits.create!(
          parent_domain_commit: parent,
          created_by: actor,
          message: message,
          state_hash: state_hash(parent:, entries: entries),
          metadata: {
            "hash_version" => HASH_VERSION
          }
        )
        entries.each do |entry|
          commit.domain_commit_documents.create!(
            document: entry.fetch(:document),
            revision: entry.fetch(:revision),
            document_key: entry.fetch(:document).key,
            revision_hash: entry.fetch(:revision_hash)
          )
        end
        domain.update!(head_domain_commit: commit)
        commit
      end
    end

    private

    attr_reader :domain, :message, :actor

    def document_entries
      domain.documents
        .includes(:head_revision)
        .where.not(head_revision_id: nil)
        .order(:key, :title, :created_at)
        .map do |document|
          revision = document.head_revision
          {
            document: document,
            revision: revision,
            revision_hash: revision_hash(revision)
          }
        end
    end

    def state_hash(parent:, entries:)
      payload = {
        "hash_version" => HASH_VERSION,
        "parent" => parent&.state_hash,
        "documents" => entries.map do |entry|
          document = entry.fetch(:document)
          revision = entry.fetch(:revision)
          {
            "document_key" => document.key,
            "revision_hash" => entry.fetch(:revision_hash)
          }
        end
      }
      digest(payload)
    end

    def revision_hash(revision)
      digest(
        "body" => revision.body
      )
    end

    def digest(value)
      Digest::SHA256.hexdigest(canonical_json(value))
    end

    def canonical_json(value)
      JSON.generate(canonicalize(value))
    end

    def canonicalize(value)
      case value
      when Hash
        value.keys.sort_by(&:to_s).each_with_object({}) do |key, canonical|
          canonical[key.to_s] = canonicalize(value[key])
        end
      when Array
        value.map { |item| canonicalize(item) }
      else
        value
      end
    end
  end
end
