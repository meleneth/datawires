# frozen_string_literal: true

module RobertsRules
  class ApplyMotion
    class Error < StandardError; end

    SUPPORTED_TYPES = %w[main extend amend close].freeze

    def self.call(motion_document:, actor: nil)
      new(motion_document:, actor:).call
    end

    def initialize(motion_document:, actor:)
      raise ArgumentError, "motion_document must be a Document" unless motion_document.is_a?(Document)

      @motion_document = motion_document
      @domain = motion_document.domain
      @actor = actor
      @changed_documents = []
    end

    def call
      revision_pairs = ApplicationRecord.transaction do
        ensure_motion_document!
        ensure_adopted_motion!
        ensure_supported_motion_type!
        ensure_not_already_applied!

        agreement = apply_agreement_change!
        mark_motion_applied!(agreement)
        event = record_proceeding_event!(agreement)
        create_domain_commit!
        changed_documents.map { |document| [ document, document.head_revision ] }
      end
      enqueue_index_rebuilds(revision_pairs)
      revision_pairs
    end

    private

    attr_reader :motion_document, :domain, :actor, :changed_documents

    def ensure_motion_document!
      return if motion_document.schema_document&.key == "motion"

      raise Error, "document is not a Robert's Rules motion"
    end

    def ensure_adopted_motion!
      return if motion_body["status"] == "adopted"

      raise Error, "only adopted motions can be applied"
    end

    def ensure_supported_motion_type!
      return if SUPPORTED_TYPES.include?(motion_type)

      raise Error, "motion type is not supported for agreement application"
    end

    def ensure_not_already_applied!
      return unless motion_body["result"].to_s.start_with?("applied")

      raise Error, "motion has already been applied"
    end

    def apply_agreement_change!
      case motion_type
      when "main"
        create_agreement!(motion_body["target_agreement_key"].presence || default_new_agreement_key, extends_agreement_key: nil)
      when "extend"
        target = target_agreement!
        create_agreement!(default_new_agreement_key, extends_agreement_key: target.key)
      when "amend"
        revise_agreement!(target_agreement!, status: "amended")
      when "close"
        revise_agreement!(target_agreement!, status: "closed")
      end
    end

    def create_agreement!(key, extends_agreement_key:)
      agreement = domain.documents.find_or_initialize_by(key: key)
      agreement.title = motion_body["title"].presence || key.titleize
      agreement.schema_document = agreement_schema
      agreement.save!

      body = {
        "title" => agreement.title,
        "status" => "active",
        "body" => motion_body["proposed_text"].presence || motion_body["title"].to_s,
        "relative_time" => motion_body["relative_time"],
        "extends_agreement_key" => extends_agreement_key,
        "notes" => motion_body["notes"]
      }.compact
      revise_document!(agreement, body, "Apply motion #{motion_document.key}")
      agreement
    end

    def revise_agreement!(agreement, status:)
      body = deep_dup_json(agreement.body)
      body["status"] = status
      body["body"] = motion_body["proposed_text"] if motion_body["proposed_text"].present?
      body["relative_time"] = motion_body["relative_time"] if motion_body.key?("relative_time")
      revise_document!(agreement, body, "Apply motion #{motion_document.key}")
      agreement
    end

    def mark_motion_applied!(agreement)
      body = deep_dup_json(motion_body)
      body["result"] = "applied: #{agreement.key}"
      revise_document!(motion_document, body, "Mark motion applied")
    end

    def record_proceeding_event!(agreement)
      event = domain.documents.find_or_initialize_by(key: "#{motion_document.key}-applied-event")
      event.title = "Applied #{motion_body["title"].presence || motion_document.title}"
      event.schema_document = proceeding_event_schema
      event.save!

      body = {
        "relative_time" => motion_body["relative_time"],
        "event_type" => "rule",
        "title" => event.title,
        "motion_key" => motion_document.key,
        "agreement_key" => agreement.key,
        "summary" => "Applied #{motion_type} motion to agreement #{agreement.key}."
      }.compact
      revise_document!(event, body, "Record applied motion")
      event
    end

    def revise_document!(document, body, message)
      revision = document.revisions.create!(
        parent_revision: document.head_revision,
        body: body,
        message: message,
        created_by: actor
      )
      document.update!(head_revision: revision)
      changed_documents << document unless changed_documents.include?(document)
      revision
    end

    def create_domain_commit!
      return unless domain.repository_mode?

      DomainCommits::Create.call(
        domain: domain,
        message: "Apply motion #{motion_document.key}",
        actor: actor
      )
    end

    def enqueue_index_rebuilds(revision_pairs)
      revision_pairs.each do |document, revision|
        DocumentIndexes::RebuildJob.perform_later(document.id, revision.id)
      end
    end

    def default_new_agreement_key
      "#{motion_document.key}-agreement"
    end

    def target_agreement!
      key = motion_body["target_agreement_key"].presence
      raise Error, "motion must target an agreement" if key.blank?

      agreement = domain.documents.find_by(key: key)
      return agreement if agreement&.schema_document&.key == "agreement"

      raise Error, "target agreement was not found"
    end

    def agreement_schema
      @agreement_schema ||= domain.documents.find_by!(key: "agreement")
    end

    def proceeding_event_schema
      @proceeding_event_schema ||= domain.documents.find_by!(key: "proceeding-event")
    end

    def motion_body
      @motion_body ||= motion_document.body
    end

    def motion_type
      motion_body["motion_type"]
    end

    def deep_dup_json(value)
      Marshal.load(Marshal.dump(value))
    end
  end
end
