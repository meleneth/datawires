# frozen_string_literal: true

require "rails_helper"

RSpec.describe UuidTools do
  it "derives stable, distinct UUID identities from a command id" do
    command_id = SecureRandom.uuid

    question_id = described_class.derive(command_id, "pending_question")

    expect(question_id).to match(described_class::FORMAT)
    expect(question_id).to eq(described_class.derive(command_id, "pending_question"))
    expect(question_id).not_to eq(described_class.derive(command_id, "decision"))
    expect(question_id).not_to eq(command_id)
  end
end
