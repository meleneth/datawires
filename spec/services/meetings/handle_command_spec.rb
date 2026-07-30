# frozen_string_literal: true

require "rails_helper"

RSpec.describe Meetings::HandleCommand do
  it "runs the initial lifecycle and deterministically rebuilds its projection" do
    meeting = create(:meeting)
    actor = create(:user)
    create(:role_assignment, scope: meeting.body, actor:, role: "chair", effective_from: 1.day.ago)
    context = actor_context(actor)

    handle(meeting, context, "open_meeting", 0)
    handle(meeting, context, "establish_attendance", 1, "actor_ids" => [ actor.id ])
    handle(meeting, context, "establish_quorum", 2, "present" => true, "basis" => "members_present")
    handle(meeting, context, "adjourn_meeting", 3)

    projection = meeting.projection
    replayed = Meetings::Projection.rebuild(meeting.event_stream.event_records.reload)
    expect(projection).to eq(replayed)
    expect(projection).to have_attributes(
      revision: 4,
      status: "adjourned",
      attendance_actor_ids: [ actor.id ],
      quorum: include("present" => true)
    )
  end

  it "rejects invalid transitions and unauthorized actors without appending" do
    meeting = create(:meeting)
    actor = create(:user)
    context = actor_context(actor)

    expect {
      handle(meeting, context, "adjourn_meeting", 0)
    }.to raise_error(described_class::Rejected, /lacks an effective Body role/)
    expect(meeting.event_stream.event_records).to be_empty

    create(:role_assignment, scope: meeting.body, actor:, role: "chair", effective_from: 1.day.ago)
    expect {
      handle(meeting, context, "establish_quorum", 0, "present" => true)
    }.to raise_error(described_class::Rejected, /unavailable while the meeting is scheduled/)
    expect(meeting.event_stream.event_records).to be_empty
  end

  it "preserves optimistic concurrency conflicts from the generic event store" do
    meeting = create(:meeting)
    actor = create(:user)
    create(:role_assignment, scope: meeting.body, actor:, role: "chair", effective_from: 1.day.ago)
    context = actor_context(actor)
    handle(meeting, context, "open_meeting", 0)

    expect {
      handle(meeting, context, "establish_quorum", 0, "present" => true)
    }.to raise_error(EventStreams::Conflict)
  end

  it "honors an effective Meeting-scoped temporary chair assignment" do
    meeting = create(:meeting)
    actor = create(:user)
    create(:role_assignment, scope: meeting, actor:, role: "temporary_chair", effective_from: 1.day.ago)

    expect {
      handle(meeting, actor_context(actor), "open_meeting", 0)
    }.to change(EventRecord, :count).by(1)
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
    described_class.call(meeting:, command:)
  end

  def actor_context(user)
    ActorContext.new(
      user:,
      claims: Identity::Claims.new(issuer: "spec", subject: user.id, name: "Chair")
    )
  end
end
