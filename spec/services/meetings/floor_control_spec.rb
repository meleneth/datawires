# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Meeting floor control" do
  it "rebuilds recognition, floor ownership, and relinquishment history" do
    meeting, chair, member = prepared_meeting
    open_meeting(meeting, chair)
    handle(meeting, member, "request_recognition", 1, "reason" => "make a motion")
    handle(meeting, chair, "recognize_member", 2, "actor_id" => member.user.id, "reason" => "make a motion")

    holding = meeting.projection
    expect(holding.floor_holder_id).to eq(member.user.id)
    expect(holding.recognition_requests).to be_empty
    expect(holding.floor_reason).to eq("make a motion")

    handle(meeting, member, "relinquish_floor", 3, "reason" => "motion completed")

    replayed = Meetings::Projection.rebuild(meeting.event_stream.event_records.reload)
    expect(replayed.floor_holder_id).to be_nil
    expect(replayed.floor_history.last).to include(
      "actor_id" => member.user.id,
      "end_reason" => "motion completed"
    )
  end

  it "rejects duplicate requests, recognition without a request, and non-holder relinquishment" do
    meeting, chair, member = prepared_meeting
    other = member_context(meeting.body)
    open_meeting(meeting, chair)
    handle(meeting, member, "request_recognition", 1)

    expect {
      handle(meeting, member, "request_recognition", 2)
    }.to raise_error(Meetings::HandleCommand::Rejected, /already has a recognition request/)
    expect {
      handle(meeting, chair, "recognize_member", 2, "actor_id" => other.user.id)
    }.to raise_error(Meetings::HandleCommand::Rejected, /has not requested recognition/)

    handle(meeting, chair, "recognize_member", 2, "actor_id" => member.user.id)
    expect {
      handle(meeting, other, "relinquish_floor", 3)
    }.to raise_error(Meetings::HandleCommand::Rejected, /Only the current floor holder/)
  end

  it "serializes simultaneous recognition commands against the stream revision" do
    meeting, chair, member = prepared_meeting
    other = member_context(meeting.body)
    open_meeting(meeting, chair)
    handle(meeting, member, "request_recognition", 1)

    expect {
      handle(meeting, other, "request_recognition", 1)
    }.to raise_error(EventStreams::Conflict)
    expect(meeting.projection.recognition_requests.map { |request| request["actor_id"] }).to eq([ member.user.id ])
  end

  it "ends a floor grant and pending requests when the meeting adjourns" do
    meeting, chair, member = prepared_meeting
    other = member_context(meeting.body)
    open_meeting(meeting, chair)
    handle(meeting, member, "request_recognition", 1)
    handle(meeting, chair, "recognize_member", 2, "actor_id" => member.user.id)
    handle(meeting, other, "request_recognition", 3)
    handle(meeting, chair, "adjourn_meeting", 4)

    projection = meeting.projection
    expect(projection.floor_holder_id).to be_nil
    expect(projection.recognition_requests).to be_empty
    expect(projection.floor_history.last["end_reason"]).to eq("meeting_adjourned")
  end

  def prepared_meeting
    meeting = create(:meeting)
    chair = member_context(meeting.body, role: "chair")
    member = member_context(meeting.body)
    [ meeting, chair, member ]
  end

  def member_context(body, role: nil)
    user = create(:user)
    create(:membership, body:, actor: user)
    create(:role_assignment, scope: body, actor: user, role:) if role
    ActorContext.new(
      user:,
      claims: Identity::Claims.new(issuer: "spec", subject: user.id, name: "Member")
    )
  end

  def open_meeting(meeting, chair)
    handle(meeting, chair, "open_meeting", 0)
  end

  def handle(meeting, actor, type, revision, payload = {})
    command = Commands::Envelope.new(
      id: SecureRandom.uuid,
      type:,
      version: 1,
      stream_id: meeting.event_stream.id,
      expected_revision: revision,
      actor:,
      timestamp: Time.current,
      payload:
    )
    Meetings::HandleCommand.call(meeting:, command:)
  end
end
