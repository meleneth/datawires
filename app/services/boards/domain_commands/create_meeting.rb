# frozen_string_literal: true

module Boards
  module DomainCommands
    class CreateMeeting < Base
      def decision
        available = body_options(:create_meeting).any?
        Authorization::Decision.new(
          allowed: available,
          reason: available ? nil : "Create a Body, or obtain its chair or secretary role, first."
        )
      end

      def fields
        [
          body_field(:create_meeting),
          Field.new(name: "title", label: "Title", type: "text", required: true, options: nil),
          Field.new(name: "scheduled_at", label: "Scheduled at", type: "datetime-local", required: true, options: nil)
        ]
      end

      def call(parameters)
        body = body_from(parameters)
        authorize_body!(body, :create_meeting)
        result = ::CreateMeeting.call(
          body:,
          title: parameters.fetch(:title),
          scheduled_at: Time.zone.parse(parameters.fetch(:scheduled_at)),
          actor: actor.user
        )
        Result.new(location: Rails.application.routes.url_helpers.document_path(result.document), notice: "Meeting created.")
      end
    end
  end
end
