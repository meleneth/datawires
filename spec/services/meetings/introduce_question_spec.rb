# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Introducing a pending question from a Proposal" do
  it "uses policy-defined recognition, scheduling, lineage, event, and stack effects" do
    meeting, chair, member = prepared_meeting
    proposal = create(:proposal, body: meeting.body)
    handle(meeting, chair, "open_meeting", 0)
    handle(meeting, chair, "schedule_proposal", 1, { "proposal_id" => proposal.id })
    expect(meeting.projection.pending_question_stack).to be_empty

    expect {
      handle(
        meeting,
        member,
        "introduce_question_from_proposal",
        2,
        { "proposal_id" => proposal.id }
      )
    }.to raise_error(Meetings::HandleCommand::Rejected, "The actor must hold the floor.")

    handle(meeting, member, "request_recognition", 2)
    handle(meeting, chair, "recognize_member", 3, { "actor_id" => member.user.id })
    command_id = SecureRandom.uuid
    handle(
      meeting,
      member,
      "introduce_question_from_proposal",
      4,
      { "proposal_id" => proposal.id },
      command_id:
    )

    record = meeting.event_stream.event_records.last
    question = meeting.projection.pending_question_stack.last
    question_id = UuidTools.derive(command_id, "pending_question")
    expect(record.event_type).to eq("MotionMade")
    expect(question).to include(
      "id" => question_id,
      "motion_id" => command_id,
      "version" => 1,
      "status" => "introduced",
      "proposal_id" => proposal.id,
      "proposal_revision_id" => proposal.submitted_revision_id,
      "content" => { "text" => "Proposed text" },
      "made_by_id" => member.user.id
    )
    expect(record.payload).to include(
      "motion_id" => command_id,
      "question_id" => question_id,
      "proposal_revision_id" => proposal.submitted_revision_id
    )

    expect {
      handle(meeting, member, "second_pending_question", 5)
    }.to raise_error(Meetings::HandleCommand::Rejected, "The maker may not second the same motion.")

    seconder = actor_context(create(:user))
    create(:membership, body: meeting.body, actor: seconder.user)
    handle(meeting, seconder, "second_pending_question", 5)
    seconded = meeting.projection.pending_question_stack.last
    expect(seconded).to include(
      "id" => question_id,
      "motion_id" => command_id,
      "status" => "seconded",
      "seconded_by_id" => seconder.user.id
    )
    expect(meeting.event_stream.event_records.last).to have_attributes(
      event_type: "MotionSeconded",
      payload: include("motion_id" => command_id, "question_id" => question_id)
    )

    handle(
      meeting,
      chair,
      "rule_pending_question_in_order",
      6,
      { "rationale" => "A main question is permitted.", "authority" => "adopted authority" }
    )
    ruled = meeting.projection.pending_question_stack.last
    expect(ruled).to include(
      "status" => "in_order",
      "ruling" => "in_order",
      "ruling_authority" => "adopted authority",
      "ruled_by_id" => chair.user.id
    )
    expect(meeting.event_stream.event_records.last.event_type).to eq("MotionRuledInOrder")

    handle(meeting, chair, "open_debate_on_pending_question", 7)
    debating = meeting.projection.pending_question_stack.last
    expect(debating).to include(
      "status" => "debate_open",
      "debate_opened_by_id" => chair.user.id
    )
    expect(meeting.event_stream.event_records.last.event_type).to eq("DebateOpened")
    expect(Meetings::Projection.rebuild(meeting.event_stream.event_records.reload)).to eq(meeting.projection)
  end

  it "preserves the submitted content after the Proposal document changes" do
    meeting, chair, member = prepared_meeting
    proposal = create(:proposal, body: meeting.body)
    handle(meeting, chair, "open_meeting", 0)
    handle(meeting, chair, "schedule_proposal", 1, { "proposal_id" => proposal.id })
    handle(meeting, member, "request_recognition", 2)
    handle(meeting, chair, "recognize_member", 3, { "actor_id" => member.user.id })
    handle(
      meeting,
      member,
      "introduce_question_from_proposal",
      4,
      { "proposal_id" => proposal.id }
    )
    revision = proposal.proposal_document.revisions.create!(
      parent_revision: proposal.proposal_document.head_revision,
      body: proposal.proposal_document.body.merge("content" => { "text" => "Later edit" }),
      message: "Edit Proposal",
      created_by: proposal.submitted_by
    )
    proposal.proposal_document.update!(head_revision: revision)

    expect(meeting.projection.pending_question_stack.last.fetch("content")).to eq(
      "text" => "Proposed text"
    )
  end

  it "records an out-of-order ruling and removes the question from the pending stack" do
    meeting, chair, member = prepared_meeting
    seconder = actor_context(create(:user))
    create(:membership, body: meeting.body, actor: seconder.user)
    proposal = create(:proposal, body: meeting.body)
    handle(meeting, chair, "open_meeting", 0)
    handle(meeting, chair, "schedule_proposal", 1, { "proposal_id" => proposal.id })
    handle(meeting, member, "request_recognition", 2)
    handle(meeting, chair, "recognize_member", 3, { "actor_id" => member.user.id })
    handle(
      meeting,
      member,
      "introduce_question_from_proposal",
      4,
      { "proposal_id" => proposal.id }
    )
    handle(meeting, seconder, "second_pending_question", 5)

    handle(
      meeting,
      chair,
      "rule_pending_question_out_of_order",
      6,
      { "rationale" => "The question conflicts with an adopted rule.", "authority" => "bylaws" }
    )

    record = meeting.event_stream.event_records.last
    expect(record).to have_attributes(
      event_type: "MotionRuledOutOfOrder",
      payload: include(
        "rationale" => "The question conflicts with an adopted rule.",
        "authority" => "bylaws",
        "ruled_by_id" => chair.user.id
      )
    )
    expect(meeting.projection.pending_question_stack).to be_empty
  end

  def prepared_meeting
    meeting = create(:meeting)
    chair = actor_context(create(:user))
    member = actor_context(create(:user))
    create(:role_assignment, scope: meeting.body, actor: chair.user, role: "chair")
    create(:membership, body: meeting.body, actor: member.user)
    [ meeting, chair, member ]
  end

  def handle(meeting, actor, type, revision, payload = {}, command_id: SecureRandom.uuid)
    command = Commands::Envelope.new(
      id: command_id,
      type:,
      version: 1,
      stream_id: meeting.event_stream_id,
      expected_revision: revision,
      actor:,
      timestamp: Time.current,
      payload:
    )
    Meetings::HandleCommand.call(meeting:, command:)
  end

  def actor_context(user)
    ActorContext.new(
      user:,
      claims: Identity::Claims.new(issuer: "spec", subject: user.id, name: "Actor")
    )
  end
end
