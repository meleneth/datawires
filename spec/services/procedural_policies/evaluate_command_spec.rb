# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProceduralPolicies::EvaluateCommand do
  it "evaluates stack conditions and resolves stack effects from policy data" do
    meeting = create(:meeting)
    actor = create(:user)
    entry = { "id" => SecureRandom.uuid, "kind" => "example" }
    definition = command_definition(entry.fetch("id"))
    command = Commands::Envelope.new(
      id: SecureRandom.uuid,
      type: definition.name,
      version: definition.command_version,
      stream_id: meeting.event_stream_id,
      expected_revision: 0,
      actor: actor_context(actor),
      timestamp: Time.current
    )
    projection = Meetings::Projection.empty.with(pending_question_stack: [ entry ])

    result = described_class.call(meeting:, command:, definition:, projection:)

    expect(result.projection_effects).to eq(
      [ "op" => "stack_pop", "field" => "pending_question_stack" ]
    )
  end

  it "rejects a policy command whose stack prerequisite is not satisfied" do
    meeting = create(:meeting)
    actor = create(:user)
    definition = command_definition(SecureRandom.uuid)
    command = Commands::Envelope.new(
      id: SecureRandom.uuid,
      type: definition.name,
      version: definition.command_version,
      stream_id: meeting.event_stream_id,
      expected_revision: 0,
      actor: actor_context(actor),
      timestamp: Time.current
    )

    expect {
      described_class.call(
        meeting:,
        command:,
        definition:,
        projection: Meetings::Projection.empty
      )
    }.to raise_error(described_class::Rejected, "A stack entry is required.")
  end

  it "resolves rejected-amendment disposition effects from policy data" do
    meeting = create(:meeting)
    actor = create(:user)
    main = {
      "id" => SecureRandom.uuid,
      "kind" => "main",
      "version" => 1,
      "status" => "vote_closed",
      "content" => { "text" => "Original" }
    }
    amendment = {
      "id" => SecureRandom.uuid,
      "amendment_id" => SecureRandom.uuid,
      "motion_id" => SecureRandom.uuid,
      "kind" => "amendment",
      "version" => 1,
      "status" => "result_announced"
    }
    vote_id = SecureRandom.uuid
    projection = Meetings::Projection.empty.with(
      status: "open",
      pending_question_stack: [ main, amendment ],
      vote_state: {
        "id" => vote_id,
        "result" => { "adopted" => false }
      }
    )
    definition = ProceduralPolicies::Projection
      .build(ProceduralPolicies::Defaults.meeting_lifecycle)
      .command("dispose_rejected_amendment")
    command = Commands::Envelope.new(
      id: SecureRandom.uuid,
      type: definition.name,
      version: definition.command_version,
      stream_id: meeting.event_stream_id,
      expected_revision: 0,
      actor: actor_context(actor),
      timestamp: Time.current
    )

    evaluation = described_class.call(meeting:, command:, definition:, projection:)
    result = ProceduralPolicies::ApplyEffects.call(
      state: projection.to_h,
      effects: evaluation.projection_effects
    )

    expect(evaluation.event_payload).to include(
      "amendment_id" => amendment.fetch("amendment_id"),
      "parent_question_id" => main.fetch("id"),
      "vote_id" => vote_id
    )
    expect(result.fetch(:pending_question_stack)).to eq(
      [ main.merge("status" => "debate_open") ]
    )
    expect(result.fetch(:vote_state)).to be_nil
  end

  def command_definition(entry_id)
    body = ProceduralPolicies::Defaults.meeting_lifecycle.deep_dup
    body["commands"] = {
      "consume_stack_entry" => {
        "capability" => "chair_action",
        "allowed_statuses" => [ "scheduled" ],
        "event_type" => "StackEntryConsumed",
        "event_version" => 1,
        "conditions" => [
          {
            "op" => "stack_present",
            "field" => "pending_question_stack",
            "reason" => "A stack entry is required."
          },
          {
            "op" => "stack_top_equals",
            "field" => "pending_question_stack",
            "match_field" => "id",
            "value" => { "source" => "literal", "value" => entry_id }
          }
        ],
        "effects" => [
          { "op" => "stack_pop", "field" => "pending_question_stack" }
        ]
      }
    }
    ProceduralPolicies::Projection.build(body).command("consume_stack_entry")
  end

  def actor_context(user)
    ActorContext.new(
      user:,
      claims: Identity::Claims.new(issuer: "spec", subject: user.id, name: "Actor")
    )
  end
end
