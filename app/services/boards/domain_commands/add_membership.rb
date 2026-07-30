# frozen_string_literal: true

module Boards
  module DomainCommands
    class AddMembership < Base
      def decision
        administration_decision
      end

      def fields
        [ body_field(:administer_board), identity_field ]
      end

      def call(parameters)
        body = body_from(parameters)
        authorize_administration!(body)
        member = actor_from(parameters.fetch(:actor_identity))
        if body.memberships.effective_at(effective_time).exists?(actor: member)
          raise ArgumentError, "That actor is already an active member of this Body."
        end

        Membership.create!(
          body:,
          actor: member,
          status: "active",
          effective_from: effective_time,
          recorded_by: actor.user,
          provenance: { "source" => "board_domain_command", "command" => "add_membership" }
        )
        Result.new(location: Rails.application.routes.url_helpers.document_path(body.body_document), notice: "Member added.")
      end
    end
  end
end
