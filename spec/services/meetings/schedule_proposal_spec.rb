# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Scheduling a Proposal" do
  it "records the submitted revision without creating pending business" do
    meeting = create(:meeting)
    chair = chair_context(meeting.body)
    proposal = create(:proposal, body: meeting.body)

    handle(meeting, chair, proposal, revision: 0)

    projection = meeting.projection
    expect(projection.scheduled_proposals).to contain_exactly(
      include(
        "proposal_id" => proposal.id,
        "proposal_revision_id" => proposal.submitted_revision_id
      )
    )
    expect(projection.pending_question_stack).to be_empty
    expect(meeting.event_stream.event_records.last.event_type).to eq("ProposalScheduled")
  end

  it "rejects duplicate and cross-Body scheduling" do
    meeting = create(:meeting)
    chair = chair_context(meeting.body)
    proposal = create(:proposal, body: meeting.body)
    handle(meeting, chair, proposal, revision: 0)

    expect {
      handle(meeting, chair, proposal, revision: 1)
    }.to raise_error(Meetings::HandleCommand::Rejected, /already scheduled/)

    other = create(:proposal)
    expect {
      handle(meeting, chair, other, revision: 1)
    }.to raise_error(Meetings::HandleCommand::Rejected, /different Body/)
  end

  def chair_context(body)
    user = create(:user)
    create(:role_assignment, scope: body, actor: user, role: "chair")
    ActorContext.new(
      user:,
      claims: Identity::Claims.new(issuer: "spec", subject: user.id, name: "Chair")
    )
  end

  def handle(meeting, actor, proposal, revision:)
    command = Commands::Envelope.new(
      id: SecureRandom.uuid,
      type: "schedule_proposal",
      version: 1,
      stream_id: meeting.event_stream.id,
      expected_revision: revision,
      actor:,
      timestamp: Time.current,
      payload: { "proposal_id" => proposal.id }
    )
    Meetings::HandleCommand.call(meeting:, command:)
  end
end
