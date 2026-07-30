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
