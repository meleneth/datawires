# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateMeeting do
  it "creates a schema-backed Meeting with an empty matching event stream" do
    body = create(:body)
    actor = create(:user)
    scheduled_at = 1.day.from_now

    result = described_class.call(body:, title: "Regular Meeting", scheduled_at:, actor:)

    expect(result.meeting.body).to eq(body)
    expect(result.document.schema_document.key).to eq(Meetings::Schema::KEY)
    expect(result.meeting.event_stream.subject_id).to eq(result.meeting.id)
    expect(result.meeting.projection).to have_attributes(revision: 0, status: "scheduled")
    expect(result.draft.created_by).to eq(actor)
  end
end
