# frozen_string_literal: true

require "rails_helper"

RSpec.describe Boards::ProposalCollection do
  it "derives open proposals from Decision document lineage" do
    board = create(:board)
    body = create(:body)
    body.body_document.update!(domain: board.schema_wrapper.domain)
    decided = create(:proposal, body:)
    open = create_proposal_like(decided, title: "Still open")
    create_decision(board.schema_wrapper.domain, decided)
    section = configure_section(board, states: %w[open])

    result = described_class.call(board:, section:)

    expect(result.documents).to eq([ open.proposal_document ])
    expect(result.error).to be_nil
  end

  private

  def create_proposal_like(proposal, title:)
    document = create(
      :document,
      :with_head_revision,
      domain: proposal.proposal_document.domain,
      schema_document: proposal.proposal_document.schema_document,
      title:,
      head_body: {
        "title" => title,
        "body_id" => proposal.body_id,
        "content" => { "text" => "Proposed text" }
      }
    )
    create(
      :proposal,
      body: proposal.body,
      proposal_document: document,
      submitted_revision: document.head_revision
    )
  end

  def create_decision(domain, proposal)
    schema = create(
      :document,
      :with_schema_head_revision,
      domain:,
      key: Decisions::Schema::KEY,
      head_body: Decisions::Schema::BODY
    )
    create(:schema_wrapper, document: schema)
    create(
      :document,
      :with_head_revision,
      domain:,
      schema_document: schema,
      head_body: {
        "decision_id" => SecureRandom.uuid,
        "meeting_id" => SecureRandom.uuid,
        "question_id" => SecureRandom.uuid,
        "question_version" => 1,
        "disposition" => "policy-defined",
        "evidence" => {},
        "lineage" => { "proposal_id" => proposal.id }
      }
    )
  end

  def configure_section(board, states:)
    body = board.body.deep_dup
    body["sections"] = [
      {
        "id" => "proposals",
        "kind" => "proposal_collection",
        "title" => "Proposals",
        "config" => {
          "states" => states,
          "order" => { "by" => "submitted_at", "direction" => "desc" },
          "limit" => 10
        }
      }
    ]
    revision = board.board_document.revisions.create!(parent_revision: board.head_revision, body:)
    board.board_document.update!(head_revision: revision)
    board.projection.sections.first
  end
end
