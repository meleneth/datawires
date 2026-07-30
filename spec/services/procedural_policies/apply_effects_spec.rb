# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProceduralPolicies::ApplyEffects do
  it "applies typed stack effects without knowing pending-question types" do
    state = Meetings::Projection.empty.to_h
    first = { "id" => SecureRandom.uuid, "version" => 1 }
    second = { "id" => SecureRandom.uuid, "version" => 1 }
    effects = [
      { "op" => "stack_push", "field" => "pending_question_stack", "value" => first },
      { "op" => "stack_push", "field" => "pending_question_stack", "value" => second },
      {
        "op" => "stack_merge_top",
        "field" => "pending_question_stack",
        "value" => { "version" => 2 }
      },
      {
        "op" => "stack_replace_top",
        "field" => "pending_question_stack",
        "value" => second.merge("version" => 3)
      },
      { "op" => "stack_pop", "field" => "pending_question_stack" }
    ]

    result = described_class.call(state:, effects:)

    expect(result.fetch(:pending_question_stack)).to eq([ first ])
    expect(result.fetch(:pending_question_stack)).to be_frozen
  end

  it "fails closed when a top-dependent effect targets an empty stack" do
    expect {
      described_class.call(
        state: Meetings::Projection.empty.to_h,
        effects: [
          {
            "op" => "stack_replace_top",
            "field" => "pending_question_stack",
            "value" => { "version" => 2 }
          }
        ]
      )
    }.to raise_error(ArgumentError, /empty stack/)
  end
end
