# frozen_string_literal: true

module Boards
  module DomainCommands
    class CreateBody < Base
      def decision
        Authorization::Policy.call(actor:, action: :create_body, resource: { domain: })
      end

      def fields
        [ Field.new(name: "name", label: "Name", type: "text", required: true, options: nil) ]
      end

      def call(parameters)
        authorization = decision
        raise Authorization::NotAuthorized, authorization.reason unless authorization.allowed?

        result = ::CreateBody.call(domain:, name: parameters.fetch(:name), actor: actor.user)
        Result.new(location: Rails.application.routes.url_helpers.document_path(result.document), notice: "Body created.")
      end
    end
  end
end
