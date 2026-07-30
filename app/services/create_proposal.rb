# frozen_string_literal: true

class CreateProposal
  Result = Data.define(:proposal, :document)

  def self.call(body:, title:, content:, summary: nil, actor:, submitted_at: Time.current)
    new(body:, title:, content:, summary:, actor:, submitted_at:).call
  end

  def initialize(body:, title:, content:, summary:, actor:, submitted_at:)
    raise ArgumentError, "body must be a Body" unless body.is_a?(Body)
    raise ArgumentError, "actor must be an ActorContext" unless actor.is_a?(ActorContext)
    raise ArgumentError, "content must be an object" unless content.is_a?(Hash)

    @body = body
    @title = title.to_s.strip
    @content = content
    @summary = summary
    @actor = actor
    @submitted_at = submitted_at.in_time_zone
  end

  def call
    decision = Authorization::Policy.call(actor:, action: :submit_proposal, resource: { body:, at: submitted_at })
    raise Authorization::NotAuthorized, decision.reason unless decision.allowed?

    ApplicationRecord.transaction do
      document = body.domain.documents.create!(
        key: next_key,
        title:,
        schema_document: proposal_schema_document
      )
      revision = document.revisions.create!(
        body: {
          "title" => title,
          "body_id" => body.id,
          "summary" => summary,
          "content" => content.deep_dup
        }.compact,
        message: "Submit proposal #{title}",
        created_by: actor.user
      )
      document.update!(head_revision: revision)
      proposal = Proposal.create!(
        proposal_document: document,
        body:,
        submitted_revision: revision,
        submitted_by: actor.user,
        submitted_at:
      )
      Result.new(proposal:, document:)
    end
  end

  private

  attr_reader :body, :title, :content, :summary, :actor, :submitted_at

  def next_key
    base = title.parameterize.presence || "proposal"
    return base unless body.domain.documents.exists?(key: base)

    index = 2
    index += 1 while body.domain.documents.exists?(key: "#{base}-#{index}")
    "#{base}-#{index}"
  end

  def proposal_schema_document
    existing = body.domain.documents.find_by(key: Proposals::Schema::KEY)
    return existing if existing&.body == Proposals::Schema::BODY
    raise ArgumentError, "proposal is not the Datawires Proposal schema" if existing

    document = body.domain.documents.create!(key: Proposals::Schema::KEY, title: "Proposal")
    revision = document.revisions.create!(
      body: Proposals::Schema::BODY,
      message: "Create Proposal schema",
      created_by: actor.user
    )
    document.update!(head_revision: revision)
    SchemaWrapper.create!(document:)
    document
  end
end
