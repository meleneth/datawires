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

    operation = {
      "version" => 1,
      "type" => "replace",
      "base_version" => 1,
      "path" => "/text",
      "value" => "Amended text"
    }
    handle(meeting, member, "move_amendment", 8, { "operation" => operation })
    main_question, amendment_question = meeting.projection.pending_question_stack
    expect(main_question).to include(
      "id" => question_id,
      "kind" => "main",
      "content" => { "text" => "Proposed text" }
    )
    expect(amendment_question).to include(
      "kind" => "amendment",
      "degree" => 1,
      "parent_question_id" => question_id,
      "parent_version" => 1,
      "operation" => operation,
      "content" => { "text" => "Amended text" }
    )
    expect(meeting.event_stream.event_records.last).to have_attributes(
      event_type: "AmendmentMoved",
      payload: include(
        "parent_question_id" => question_id,
        "operation" => operation,
        "proposed_content" => { "text" => "Amended text" }
      )
    )

    electorate = [ chair.user.id, member.user.id, seconder.user.id ]
    handle(meeting, chair, "establish_attendance", 9, { "actor_ids" => electorate })
    handle(meeting, chair, "establish_quorum", 10, { "present" => true })
    handle(meeting, seconder, "second_pending_question", 11)
    handle(
      meeting,
      chair,
      "rule_pending_question_in_order",
      12,
      { "rationale" => "The amendment is germane.", "authority" => "adopted authority" }
    )
    handle(meeting, chair, "open_debate_on_pending_question", 13)
    vote_command_id = SecureRandom.uuid
    handle(
      meeting,
      chair,
      "open_vote_on_pending_question",
      14,
      {},
      command_id: vote_command_id
    )

    vote = meeting.projection.vote_state
    expect(vote).to include(
      "id" => vote_command_id,
      "status" => "open",
      "question_id" => amendment_question.fetch("id"),
      "question_version" => 1,
      "electorate_actor_ids" => electorate,
      "method" => "counted",
      "attribution" => "attributable",
      "chair_rule" => "eligible_as_member",
      "threshold" => { "kind" => "majority", "basis" => "votes_cast" },
      "ballots" => []
    )

    handle(meeting, chair, "establish_attendance", 15, { "actor_ids" => [ chair.user.id ] })
    expect(meeting.projection.vote_state.fetch("eligible_actor_ids")).to eq(electorate)
    handle(meeting, member, "cast_counted_ballot", 16, { "choice" => "yes" })
    handle(meeting, chair, "cast_counted_ballot", 17, { "choice" => "yes" })
    expect(meeting.projection.vote_state.fetch("ballots")).to contain_exactly(
      include("actor_id" => member.user.id, "choice" => "yes"),
      include("actor_id" => chair.user.id, "choice" => "yes")
    )
    expect {
      handle(meeting, member, "cast_counted_ballot", 18, { "choice" => "abstain" })
    }.to raise_error(Meetings::HandleCommand::Rejected, "The actor has already cast a ballot.")

    handle(meeting, chair, "close_counted_vote", 18)
    closed_vote = meeting.projection.vote_state
    expect(closed_vote).to include(
      "status" => "closed",
      "result" => {
        "totals" => { "yes" => 2, "no" => 0, "abstain" => 0 },
        "threshold" => { "kind" => "majority", "basis" => "votes_cast" },
        "threshold_count" => 2,
        "basis_count" => 2,
        "adopted" => true,
        "tie" => false
      }
    )
    expect(meeting.event_stream.event_records.last.event_type).to eq("VoteClosed")

    handle(meeting, chair, "announce_counted_vote_result", 19)
    expect(meeting.projection.vote_state).to include(
      "status" => "announced",
      "result" => include("adopted" => true, "tie" => false)
    )
    expect(meeting.projection.pending_question_stack.last.fetch("status")).to eq("result_announced")
    expect(meeting.event_stream.event_records.last.event_type).to eq("VoteResultAnnounced")

    handle(meeting, chair, "dispose_adopted_amendment", 20)
    resumed = meeting.projection.pending_question_stack
    expect(resumed.length).to eq(1)
    expect(resumed.last).to include(
      "id" => question_id,
      "kind" => "main",
      "version" => 2,
      "status" => "debate_open",
      "content" => { "text" => "Amended text" },
      "last_adopted_amendment_id" => amendment_question.fetch("amendment_id")
    )
    expect(resumed.last.fetch("versions")).to contain_exactly(
      include(
        "version" => 1,
        "content" => { "text" => "Proposed text" },
        "source_proposal_revision_id" => proposal.submitted_revision_id
      ),
      include(
        "version" => 2,
        "content" => { "text" => "Amended text" },
        "amendment_id" => amendment_question.fetch("amendment_id"),
        "operation" => operation,
        "vote_id" => vote_command_id
      )
    )
    expect(meeting.projection.vote_state).to be_nil
    expect(meeting.event_stream.event_records.last.event_type).to eq("AmendmentAdopted")
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
