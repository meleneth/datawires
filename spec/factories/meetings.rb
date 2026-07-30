# frozen_string_literal: true

FactoryBot.define do
  factory :meeting do
    body
    meeting_document do
      schema = create(:document, :with_schema_head_revision, domain: body.domain, key: Meetings::Schema::KEY, head_body: Meetings::Schema::BODY)
      create(:schema_wrapper, document: schema)
      create(
        :document,
        :with_head_revision,
        domain: body.domain,
        schema_document: schema,
        head_body: { "title" => "Meeting", "body_id" => body.id, "scheduled_at" => 1.day.from_now.iso8601 }
      )
    end
    id { SecureRandom.uuid }
    event_stream do
      create(:event_stream, domain: body.domain, stream_type: "meeting", subject_id: id)
    end
    procedural_policy do
      CreateProceduralPolicy.call(
        body:,
        name: Meetings::DefaultPolicy::NAME,
        definition: Meetings::DefaultPolicy::BODY,
        actor: create(:user)
      )
    end
  end
end
