# frozen_string_literal: true

module Boards
  module DomainCommands
    class Base
      Result = Data.define(:location, :notice)
      Field = Data.define(:name, :label, :type, :required, :options)

      attr_reader :board, :actor

      def initialize(board:, actor:)
        @board = board
        @actor = actor
      end

      def domain
        board.schema_wrapper.domain
      end

      def decision
        Authorization::Decision.new(allowed: true, reason: nil)
      end

      private

      def body_from(parameters)
        bodies.find(parameters.fetch(:body_id))
      end

      def authorize_body!(body, action)
        decision = Authorization::Policy.call(actor:, action:, resource: { body: })
        raise Authorization::NotAuthorized, decision.reason unless decision.allowed?
      end

      def body_options(action)
        bodies.order(:created_at).filter_map do |body|
          decision = Authorization::Policy.call(actor:, action:, resource: { body: })
          [ body.body_document.title, body.id ] if decision.allowed?
        end
      end

      def bodies
        Body.where(body_document: domain.documents)
      end

      def body_field(action)
        Field.new(
          name: "body_id",
          label: "Body",
          type: "select",
          required: true,
          options: body_options(action)
        )
      end

      def administration_decision
        available = body_options(:administer_board).any?
        Authorization::Decision.new(
          allowed: available,
          reason: available ? nil : "Create a Body, or obtain its chair or secretary role, first."
        )
      end

      def actor_from(identifier)
        value = identifier.to_s.strip
        matches = User.where(email: value)
          .or(User.where(external_id: value))
          .or(User.where(identity_subject: value))
          .distinct
        raise ArgumentError, "No Datawires actor matches that identity." if matches.none?
        raise ArgumentError, "That identity matches more than one Datawires actor." if matches.many?

        matches.first
      end

      def identity_field
        Field.new(
          name: "actor_identity",
          label: "Actor email or identity subject",
          type: "text",
          required: true,
          options: nil
        )
      end

      def authorize_administration!(body)
        authorize_body!(body, :administer_board)
      end

      def effective_time
        Time.current
      end
    end
  end
end
