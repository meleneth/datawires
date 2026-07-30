# frozen_string_literal: true

require "rails_helper"

RSpec.describe Boards::MeetingCollection do
  it "filters and orders meeting documents by policy-derived projection status" do
    board = create(:board)
    body = create(:body)
    body.body_document.update!(domain: board.schema_wrapper.domain)
    old_meeting = create(:meeting, body:)
    recent_meeting = create_meeting_like(old_meeting)
    create(:meeting)
    append_adjournment(old_meeting)
    append_adjournment(recent_meeting)
    set_scheduled_at(old_meeting, 2.days.ago)
    set_scheduled_at(recent_meeting, 1.day.ago)
    section = configure_section(
      board,
      statuses: %w[adjourned],
      order: { "by" => "scheduled_at", "direction" => "desc" },
      limit: 1
    )

    result = described_class.call(board:, section:)

    expect(result.documents).to eq([ recent_meeting.meeting_document ])
    expect(result.error).to be_nil
  end

  private

  def create_meeting_like(meeting)
    document = create(
      :document,
      :with_head_revision,
      domain: meeting.meeting_document.domain,
      schema_document: meeting.meeting_document.schema_document,
      head_body: {
        "title" => "Another meeting",
        "body_id" => meeting.body_id,
        "scheduled_at" => 1.day.from_now.iso8601
      }
    )
    id = SecureRandom.uuid
    Meeting.create!(
      id:,
      body: meeting.body,
      meeting_document: document,
      event_stream: create(:event_stream, domain: document.domain, stream_type: "meeting", subject_id: id),
      procedural_policy: meeting.procedural_policy
    )
  end

  def append_adjournment(meeting)
    meeting.event_stream.event_records.create!(
      sequence: 1,
      event_type: "PolicyDefinedMeetingClosure",
      event_version: 1,
      command_id: SecureRandom.uuid,
      command_type: "policy_defined_closure",
      command_version: 1,
      occurred_at: Time.current,
      payload: {},
      provenance: {
        "projection_effects" => [
          { "op" => "set", "field" => "status", "value" => "adjourned" }
        ]
      }
    )
  end

  def set_scheduled_at(meeting, value)
    document = meeting.meeting_document
    revision = document.revisions.create!(
      parent_revision: document.head_revision,
      body: document.body.merge("scheduled_at" => value.iso8601)
    )
    document.update!(head_revision: revision)
  end

  def configure_section(board, statuses:, order:, limit:)
    body = board.body.deep_dup
    body["sections"] = [
      {
        "id" => "meetings",
        "kind" => "meeting_collection",
        "title" => "Meetings",
        "config" => { "statuses" => statuses, "order" => order, "limit" => limit }
      }
    ]
    revision = board.board_document.revisions.create!(parent_revision: board.head_revision, body:)
    board.board_document.update!(head_revision: revision)
    board.projection.sections.first
  end
end
