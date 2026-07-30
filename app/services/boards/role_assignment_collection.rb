# frozen_string_literal: true

module Boards
  class RoleAssignmentCollection < MembershipCollection
    def call
      rows = assignments
        .includes(:actor, :scope)
        .order(effective_from: :desc)
        .limit(config.fetch("limit", 100))
        .map do |assignment|
          Row.new(
            label: actor_label(assignment.actor),
            details: [
              assignment.role.humanize,
              scope_label(assignment.scope),
              effective_range(assignment)
            ]
          )
        end
      Result.new(rows:, empty_state: config["empty_state"].presence || "No role assignments found.", error: nil)
    end

    private

    def assignments
      body_assignments = RoleAssignment.where(scope: administrable_bodies)
      meeting_assignments = RoleAssignment.where(scope: Meeting.where(body: administrable_bodies))
      body_assignments.or(meeting_assignments)
    end

    def scope_label(scope)
      if scope.is_a?(Body)
        "#{scope.body_document.title} (Body)"
      else
        "#{scope.meeting_document.title} (Meeting)"
      end
    end
  end
end
