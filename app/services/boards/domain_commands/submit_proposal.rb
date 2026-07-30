# frozen_string_literal: true

module Boards
  module DomainCommands
    class SubmitProposal < Base
      def decision
        available = body_options(:submit_proposal).any?
        Authorization::Decision.new(
          allowed: available,
          reason: available ? nil : "Create a Body, or obtain membership in one, first."
        )
      end

      def fields
        [
          body_field(:submit_proposal),
          Field.new(name: "title", label: "Title", type: "text", required: true, options: nil),
          Field.new(name: "summary", label: "Summary", type: "textarea", required: false, options: nil),
          Field.new(name: "text", label: "Proposed text", type: "textarea", required: true, options: nil)
        ]
      end

      def call(parameters)
        body = body_from(parameters)
        authorize_body!(body, :submit_proposal)
        result = ::CreateProposal.call(
          body:,
          title: parameters.fetch(:title),
          summary: parameters[:summary].presence,
          content: { "text" => parameters.fetch(:text) },
          actor:
        )
        Result.new(location: Rails.application.routes.url_helpers.document_path(result.document), notice: "Proposal submitted.")
      end
    end
  end
end
