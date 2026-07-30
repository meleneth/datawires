# frozen_string_literal: true

require "rails_helper"

RSpec.describe Meetings::Projection do
  LegacyRecord = Data.define(
    :sequence,
    :event_type,
    :event_version,
    :payload,
    :provenance,
    :actor_id,
    :occurred_at
  )

  it "replays legacy events through versioned data mappings" do
    actor_id = SecureRandom.uuid
    proposal_id = SecureRandom.uuid
    proposal_revision_id = SecureRandom.uuid
    at = Time.current
    records = [
      record(1, "MeetingOpened", at:),
      record(2, "AttendanceEstablished", payload: { "actor_ids" => [ actor_id ] }, at:),
      record(3, "QuorumEstablished", payload: { "present" => true }, at:),
      record(4, "RecognitionRequested", payload: { "actor_id" => actor_id }, at:),
      record(5, "MemberRecognized", payload: { "actor_id" => actor_id, "reason" => "business" }, at:),
      record(6, "FloorRelinquished", payload: { "reason" => "finished" }, at:),
      record(
        7,
        "ProposalScheduled",
        payload: { "proposal_id" => proposal_id, "proposal_revision_id" => proposal_revision_id },
        actor_id:,
        at:
      ),
      record(8, "MeetingAdjourned", at:)
    ]

    projection = described_class.rebuild(records)

    expect(projection).to have_attributes(
      revision: 8,
      status: "adjourned",
      attendance_actor_ids: [ actor_id ],
      quorum: { "present" => true },
      recognition_requests: [],
      floor_holder_id: nil
    )
    expect(projection.floor_history.last).to include(
      "actor_id" => actor_id,
      "end_reason" => "finished"
    )
    expect(projection.scheduled_proposals).to eq(
      [
        {
          "proposal_id" => proposal_id,
          "proposal_revision_id" => proposal_revision_id,
          "scheduled_by_id" => actor_id
        }
      ]
    )
  end

  it "advances revision without inventing effects for an unknown legacy event version" do
    projection = described_class.empty.apply(record(1, "UnknownEvent", version: 99))

    expect(projection).to eq(described_class.empty.with(revision: 1))
  end

  def record(sequence, type, version: 1, payload: {}, actor_id: nil, at: Time.current)
    LegacyRecord.new(
      sequence:,
      event_type: type,
      event_version: version,
      payload:,
      provenance: {},
      actor_id:,
      occurred_at: at
    )
  end
end
