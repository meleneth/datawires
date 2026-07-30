# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Board relationship administration commands" do
  let(:board) { create(:board) }
  let(:administrator) { create(:user, email: "chair@example.test", name: "Chair") }
  let(:actor) { actor_context(administrator) }
  let(:body) do
    CreateBody.call(
      domain: board.schema_wrapper.domain,
      name: "General Assembly",
      actor: administrator
    ).body
  end
  let(:member) { create(:user, email: "member@example.test", name: "Member") }

  it "adds and ends a historical Body membership" do
    command = command_for("add_membership")

    result = command.call(body_id: body.id, actor_identity: member.email)

    membership = body.memberships.find_by!(actor: member)
    expect(result.notice).to eq("Member added.")
    expect(membership).to have_attributes(status: "active", recorded_by: administrator)
    expect(membership.provenance).to include("command" => "add_membership")

    ending = command_for("end_membership")
    expect(ending.fields.first.options).to include([ "Member — General Assembly", membership.id ])
    ending.call(membership_id: membership.id)

    expect(membership.reload.status).to eq("ended")
    expect(membership.effective_until).to be_present
    expect(membership.provenance).to include(
      "ended_by_actor_id" => administrator.id,
      "end_command" => "end_membership"
    )
  end

  it "assigns and ends a role scoped to a Meeting" do
    meeting = CreateMeeting.call(
      body:,
      title: "Regular Meeting",
      scheduled_at: 1.day.from_now,
      actor: administrator
    ).meeting
    command = command_for("assign_role")

    command.call(
      scope: "Meeting:#{meeting.id}",
      actor_identity: member.email,
      role: "temporary_chair"
    )

    assignment = meeting.role_assignments.find_by!(actor: member, role: "temporary_chair")
    expect(assignment.provenance).to include("command" => "assign_role")

    ending = command_for("end_role_assignment")
    expect(ending.fields.first.options).to include(
      [ "Member — Temporary chair — Regular Meeting", assignment.id ]
    )
    ending.call(role_assignment_id: assignment.id)

    expect(assignment.reload.effective_until).to be_present
    expect(assignment.provenance).to include(
      "ended_by_actor_id" => administrator.id,
      "end_command" => "end_role_assignment"
    )
  end

  it "does not derive administration from identity-provider claims" do
    body
    outsider = actor_context(
      create(:user),
      administrative_roles: [ "realm-admin" ],
      groups: [ "chairs" ]
    )
    command = Boards::DomainCommands::Registry.fetch("add_membership", board:, actor: outsider)

    expect(command.decision).not_to be_allowed
    expect { command.call(body_id: body.id, actor_identity: member.email) }
      .to raise_error(Authorization::NotAuthorized)
  end

  it "derives assignable roles from the applicable Datawires policy" do
    body
    command = command_for("assign_role")

    expect(command.fields.find { |field| field.name == "role" }.options)
      .to include([ "Chair", "chair" ], [ "Secretary", "secretary" ])
    expect {
      command.call(scope: "Body:#{body.id}", actor_identity: member.email, role: "keycloak_admin")
    }.to raise_error(ArgumentError, "Role is not defined by the applicable policy.")
  end

  def command_for(name)
    Boards::DomainCommands::Registry.fetch(name, board:, actor:)
  end

  def actor_context(user, groups: [], administrative_roles: [])
    ActorContext.new(
      user:,
      claims: Identity::Claims.new(
        issuer: "spec",
        subject: user.id,
        name: user.name || "Actor",
        groups:,
        administrative_roles:
      )
    )
  end
end
