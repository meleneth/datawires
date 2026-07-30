# frozen_string_literal: true

require "rails_helper"

RSpec.describe RoleAssignment, type: :model do
  it "retains ended assignments for historical queries" do
    time = Time.zone.parse("2026-07-29 12:00:00")
    assignment = create(:role_assignment, effective_from: time - 2.days, effective_until: time)

    expect(assignment.scope.role_assignments_at(time - 1.day)).to contain_exactly(assignment)
    expect(assignment.scope.role_assignments_at(time)).to be_empty
    expect(described_class.exists?(assignment.id)).to be(true)
  end

  it "rejects roles absent from the applicable policy and unknown scope types" do
    assignment = build(:role_assignment, role: "keycloak_admin", scope_type: "Domain")

    expect(assignment).not_to be_valid
  end
end
