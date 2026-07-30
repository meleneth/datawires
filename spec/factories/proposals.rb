# frozen_string_literal: true

FactoryBot.define do
  factory :proposal do
    body
    association :submitted_by, factory: :user
    submitted_at { Time.current }
    proposal_document do
      schema = create(:document, :with_schema_head_revision, domain: body.domain, key: Proposals::Schema::KEY, head_body: Proposals::Schema::BODY)
      create(:schema_wrapper, document: schema)
      create(
        :document,
        :with_head_revision,
        domain: body.domain,
        schema_document: schema,
        head_body: { "title" => "Proposal", "body_id" => body.id, "content" => { "text" => "Proposed text" } }
      )
    end
    submitted_revision { proposal_document.head_revision }
  end
end
