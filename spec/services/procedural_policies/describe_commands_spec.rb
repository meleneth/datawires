# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProceduralPolicies::DescribeCommands do
  it "describes authorization, prerequisites, policy conditions, and expected effects" do
    meeting = create(:meeting)
    chair = create(:user)
    member = create(:user)
    outsider = create(:user)
    create(:role_assignment, scope: meeting.body, actor: chair, role: "chair", effective_from: 1.day.ago)
    create(:membership, body: meeting.body, actor: member, effective_from: 1.day.ago)
    open_meeting(meeting, chair)

    outsider_request = find_description(meeting, outsider, "request_recognition")
    expect(outsider_request).to have_attributes(
      availability: :unavailable,
      reason: match(/lacks an effective Body role/)
    )

    chair_recognize = find_description(meeting, chair, "recognize_member")
    expect(chair_recognize).to have_attributes(
      availability: :prerequisite_needed,
      reason: "Required input: Actor."
    )

    invalid_input = find_description(
      meeting,
      chair,
      "recognize_member",
      "recognize_member" => { "actor_id" => "not-a-uuid" }
    )
    expect(invalid_input).to have_attributes(
      availability: :prerequisite_needed,
      reason: "Actor must be a uuid."
    )

    missing_request = find_description(
      meeting,
      chair,
      "recognize_member",
      "recognize_member" => { "actor_id" => member.id }
    )
    expect(missing_request).to have_attributes(
      availability: :unavailable,
      reason: "The actor has not requested recognition."
    )

    member_request = find_description(meeting, member, "request_recognition")
    expect(member_request).to be_available
    expect(member_request.expected_effects).to include(
      include("op" => "append", "field" => "recognition_requests")
    )
    expect(member_request.expected_effects).to be_frozen
    expect(meeting.event_stream.reload.revision).to eq(1)
  end

  def find_description(meeting, user, name, payloads = {})
    described_class.call(
      meeting:,
      actor: actor_context(user),
      payloads:,
      at: Time.current
    ).find { |description| description.name == name }
  end

  def open_meeting(meeting, chair)
    command = Commands::Envelope.new(
      id: SecureRandom.uuid,
      type: "open_meeting",
      version: 1,
      stream_id: meeting.event_stream_id,
      expected_revision: 0,
      actor: actor_context(chair),
      timestamp: Time.current
    )
    Meetings::HandleCommand.call(meeting:, command:)
  end

  def actor_context(user)
    ActorContext.new(
      user:,
      claims: Identity::Claims.new(issuer: "spec", subject: user.id, name: user.name)
    )
  end
end
