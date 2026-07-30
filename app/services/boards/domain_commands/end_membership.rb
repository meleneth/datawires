# frozen_string_literal: true

module Boards
  module DomainCommands
    class EndMembership < Base
      def decision
        administration_decision
      end

      def fields
        [
          Field.new(
            name: "membership_id",
            label: "Active membership",
            type: "select",
            required: true,
            options: membership_options
          )
        ]
      end

      def call(parameters)
        membership = administrable_memberships.find(parameters.fetch(:membership_id))
        authorize_administration!(membership.body)
        ended_at = effective_time
        membership.update!(
          status: "ended",
          effective_until: ended_at,
          provenance: membership.provenance.merge(
            "ended_by_actor_id" => actor.user.id,
            "ended_at" => ended_at.iso8601,
            "end_command" => "end_membership"
          )
        )
        Result.new(
          location: Rails.application.routes.url_helpers.document_path(membership.body.body_document),
          notice: "Membership ended."
        )
      end

      private

      def administrable_memberships
        Membership.where(body: administrable_bodies).effective_at(effective_time)
      end

      def administrable_bodies
        ids = body_options(:administer_board).map(&:last)
        bodies.where(id: ids)
      end

      def membership_options
        administrable_memberships.includes(:actor, body: :body_document).map do |membership|
          identity = membership.actor.name.presence || membership.actor.email.presence || membership.actor.external_id
          [ "#{identity} — #{membership.body.body_document.title}", membership.id ]
        end
      end
    end
  end
end
