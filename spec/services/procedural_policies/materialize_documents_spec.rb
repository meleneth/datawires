# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProceduralPolicies::MaterializeDocuments do
  it "idempotently materializes a registered schema-backed output" do
    meeting = create(:meeting)
    actor = create(:user)
    actor_context = ActorContext.new(
      user: actor,
      claims: Identity::Claims.new(issuer: "spec", subject: actor.id, name: "Actor")
    )
    decision_id = SecureRandom.uuid
    output = {
      "type" => "decision",
      "id" => decision_id,
      "title" => "Decision",
      "body" => {
        "decision_id" => decision_id,
        "meeting_id" => meeting.id,
        "question_id" => SecureRandom.uuid,
        "question_version" => 1,
        "disposition" => "rejected",
        "evidence" => {}
      }
    }

    first = described_class.call(meeting:, actor: actor_context, outputs: [ output ]).first
    second = described_class.call(meeting:, actor: actor_context, outputs: [ output ]).first

    expect(second).to eq(first)
    expect(first.schema_document.key).to eq(Decisions::Schema::KEY)
    expect(meeting.body.domain.documents.where(key: decision_id).count).to eq(1)
  end

  it "fails closed when a derived output id conflicts with other content" do
    meeting = create(:meeting)
    actor = create(:user)
    actor_context = ActorContext.new(
      user: actor,
      claims: Identity::Claims.new(issuer: "spec", subject: actor.id, name: "Actor")
    )
    id = SecureRandom.uuid
    meeting.body.domain.documents.create!(key: id, title: "Existing")

    expect {
      described_class.call(
        meeting:,
        actor: actor_context,
        outputs: [
          {
            "type" => "decision",
            "id" => id,
            "title" => "Decision",
            "body" => {}
          }
        ]
      )
    }.to raise_error(ArgumentError, /conflicts with existing content/)
  end
end
