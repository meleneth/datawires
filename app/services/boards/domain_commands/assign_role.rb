# frozen_string_literal: true

module Boards
  module DomainCommands
    class AssignRole < Base
      def decision
        administration_decision
      end

      def fields
        [
          Field.new(name: "scope", label: "Scope", type: "select", required: true, options: scope_options),
          identity_field,
          Field.new(
            name: "role",
            label: "Role",
            type: "select",
            required: true,
            options: available_roles.map { |role| [ role.humanize, role ] }
          )
        ]
      end

      def call(parameters)
        scope = scope_from(parameters.fetch(:scope))
        body = scope.is_a?(Body) ? scope : scope.body
        authorize_administration!(body)
        assignee = actor_from(parameters.fetch(:actor_identity))
        role = parameters.fetch(:role)
        raise ArgumentError, "Role is not defined by the applicable policy." unless roles_for_scope(scope).include?(role)
        if scope.role_assignments.effective_at(effective_time).exists?(actor: assignee, role:)
          raise ArgumentError, "That actor already has this effective role in the selected scope."
        end

        RoleAssignment.create!(
          actor: assignee,
          scope:,
          role:,
          effective_from: effective_time,
          recorded_by: actor.user,
          provenance: { "source" => "board_domain_command", "command" => "assign_role" }
        )
        Result.new(location: Rails.application.routes.url_helpers.document_path(body.body_document), notice: "Role assigned.")
      end

      private

      def scope_options
        body_options(:administer_board).flat_map do |label, body_id|
          body = bodies.find(body_id)
          body_option = [ "#{label} (Body)", "Body:#{body.id}" ]
          meeting_options = body.meetings.includes(:meeting_document).order(:created_at).map do |meeting|
            [ "#{meeting.meeting_document.title} (Meeting)", "Meeting:#{meeting.id}" ]
          end
          [ body_option, *meeting_options ]
        end
      end

      def scope_from(value)
        type, id = value.to_s.split(":", 2)
        case type
        when "Body"
          bodies.find(id)
        when "Meeting"
          Meeting.joins(body: :body_document).where(documents: { domain_id: domain.id }).find(id)
        else
          raise ArgumentError, "Unknown role scope."
        end
      end

      def available_roles
        administrable_scopes.flat_map { |scope| roles_for_scope(scope) }.uniq.sort
      end

      def administrable_scopes
        body_options(:administer_board).flat_map do |_label, body_id|
          body = bodies.find(body_id)
          [ body, *body.meetings.includes(:procedural_policy) ]
        end
      end

      def roles_for_scope(scope)
        if scope.is_a?(Meeting)
          scope.procedural_policy.projection.roles
        else
          policies = scope.procedural_policies.map { |policy| policy.projection.roles }
          policies.flatten.uniq.presence || Authorization::BodyPolicy.default_capability_policy.roles
        end
      end
    end
  end
end
