# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateProposal do
  it "submits a schema-backed Proposal with immutable revision lineage" do
    body = create(:body)
    actor = member_context(body)

    result = described_class.call(
      body:,
      title: "Adopt the budget",
      summary: "Annual budget",
      content: { "text" => "Resolved, that the budget is adopted." },
      actor:
    )

    expect(result.proposal.submitted_revision).to eq(result.document.head_revision)
    expect(result.proposal.submitted_by).to eq(actor.user)
    expect(result.document.schema_document.key).to eq(Proposals::Schema::KEY)
    expect(result.document.body.dig("content", "text")).to include("budget")
  end

  it "rejects an actor without an effective Body relationship" do
    body = create(:body)
    actor = actor_context(create(:user))

    expect {
      described_class.call(body:, title: "Unauthorized", content: {}, actor:)
    }.to raise_error(Authorization::NotAuthorized)
  end

  def member_context(body)
    user = create(:user)
    create(:membership, body:, actor: user)
    actor_context(user)
  end

  def actor_context(user)
    ActorContext.new(
      user:,
      claims: Identity::Claims.new(issuer: "spec", subject: user.id, name: "Member")
    )
  end
end
