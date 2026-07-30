# frozen_string_literal: true

module Boards
  module DomainCommands
    class EndRoleAssignment < Base
      def decision
        administration_decision
      end

      def fields
        [
          Field.new(
            name: "role_assignment_id",
            label: "Effective role assignment",
            type: "select",
            required: true,
            options: role_assignment_options
          )
        ]
      end

      def call(parameters)
        assignment = administrable_assignments.find(parameters.fetch(:role_assignment_id))
        body = assignment.scope.is_a?(Body) ? assignment.scope : assignment.scope.body
        authorize_administration!(body)
        ended_at = effective_time
        assignment.update!(
          effective_until: ended_at,
          provenance: assignment.provenance.merge(
            "ended_by_actor_id" => actor.user.id,
            "ended_at" => ended_at.iso8601,
            "end_command" => "end_role_assignment"
          )
        )
        Result.new(
          location: Rails.application.routes.url_helpers.document_path(body.body_document),
          notice: "Role assignment ended."
        )
      end

      private

      def administrable_assignments
        body_scope = RoleAssignment.where(scope: administrable_bodies)
        meeting_scope = RoleAssignment.where(scope: Meeting.where(body: administrable_bodies))
        body_scope.or(meeting_scope).effective_at(effective_time)
      end

      def administrable_bodies
        ids = body_options(:administer_board).map(&:last)
        bodies.where(id: ids)
      end

      def role_assignment_options
        administrable_assignments.includes(:actor, :scope).map do |assignment|
          identity = assignment.actor.name.presence || assignment.actor.email.presence || assignment.actor.external_id
          scope_title = if assignment.scope.is_a?(Body)
            assignment.scope.body_document.title
          else
            assignment.scope.meeting_document.title
          end
          [ "#{identity} — #{assignment.role.humanize} — #{scope_title}", assignment.id ]
        end
      end
    end
  end
end
