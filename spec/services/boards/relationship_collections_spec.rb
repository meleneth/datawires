# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Board relationship collections" do
  let(:board) { create(:board) }
  let(:chair) { create(:user, name: "Chair") }
  let(:member) { create(:user, name: "Member") }
  let(:body) do
    CreateBody.call(
      domain: board.schema_wrapper.domain,
      name: "General Assembly",
      actor: chair
    ).body
  end

  it "projects membership and scoped-role history for policy-authorized administrators" do
    membership = create(:membership, body:, actor: member)
    assignment = create(:role_assignment, scope: body, actor: member, role: "secretary")

    memberships = Boards::MembershipCollection.call(
      board:,
      section: section("membership_collection"),
      actor: actor_context(chair)
    )
    roles = Boards::RoleAssignmentCollection.call(
      board:,
      section: section("role_assignment_collection"),
      actor: actor_context(chair)
    )

    expect(memberships.rows.map(&:label)).to include("Member")
    expect(memberships.rows.flat_map(&:details)).to include("General Assembly", "Active")
    expect(roles.rows.map(&:label)).to include("Member")
    expect(roles.rows.flat_map(&:details)).to include("Secretary", "General Assembly (Body)")
    expect(membership).to be_persisted
    expect(assignment).to be_persisted
  end

  it "does not expose relationship rows to actors lacking policy administration" do
    create(:membership, body:, actor: member)
    outsider = create(:user)

    result = Boards::MembershipCollection.call(
      board:,
      section: section("membership_collection"),
      actor: actor_context(outsider)
    )

    expect(result.rows).to be_empty
  end

  def section(kind)
    Boards::Projection::Entry.new(
      id: kind,
      kind:,
      title: kind.humanize,
      description: "",
      config: { "limit" => 100 }
    )
  end

  def actor_context(user)
    ActorContext.new(
      user:,
      claims: Identity::Claims.new(issuer: "spec", subject: user.id, name: user.name || "Actor")
    )
  end
end
