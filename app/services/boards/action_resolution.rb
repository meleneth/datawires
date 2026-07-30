# frozen_string_literal: true

module Boards
  class ActionResolution
    Result = Data.define(:action, :status, :reason, :schema_wrapper, :edit_affordance, :domain_command) do
      def available?
        status == "available"
      end

      def hidden?
        status == "hidden"
      end
    end

    def self.call(board:, action:, actor:, authorizer: Authorization::Policy)
      new(board:, action:, actor:, authorizer:).call
    end

    def initialize(board:, action:, actor:, authorizer:)
      raise ArgumentError, "board must be a Board" unless board.is_a?(Board)
      raise ArgumentError, "action must be a Boards::Projection::Entry" unless action.is_a?(Boards::Projection::Entry)

      @board = board
      @action = action
      @actor = actor
      @authorizer = authorizer
    end

    def call
      return resolve_domain_command if action.kind == "invoke_command"

      schema_wrapper = target_schema_wrapper
      return unavailable("Schema #{config.fetch("schema_key")} was not found.") unless schema_wrapper

      edit_affordance = selected_edit_affordance(schema_wrapper)
      if config["edit_affordance"].present? && edit_affordance.nil?
        return unavailable("Edit affordance #{config["edit_affordance"]} was not found.", schema_wrapper:)
      end

      decision = authorizer.call(
        actor:,
        action: :create_document,
        resource: { schema_wrapper:, board: }
      )
      return denied(decision.reason, schema_wrapper:, edit_affordance:) unless decision.allowed?

      Result.new(action:, status: "available", reason: nil, schema_wrapper:, edit_affordance:, domain_command: nil)
    end

    private

    attr_reader :board, :action, :actor, :authorizer

    def config
      action.config
    end

    def target_schema_wrapper
      document = board.schema_wrapper.domain.documents.find_by(key: config.fetch("schema_key"))
      document&.schema_wrapper
    end

    def selected_edit_affordance(schema_wrapper)
      return nil if config["edit_affordance"].blank?

      schema_wrapper.edit_affordances.find_by(title: config["edit_affordance"])
    end

    def resolve_domain_command
      command = DomainCommands::Registry.fetch(config.fetch("command"), board:, actor:)
      return unavailable("Domain command #{config.fetch("command")} is not registered.") unless command

      decision = command.decision
      return denied(decision.reason, domain_command: command) unless decision.allowed?

      Result.new(
        action:,
        status: "available",
        reason: nil,
        schema_wrapper: nil,
        edit_affordance: nil,
        domain_command: command
      )
    end

    def denied(reason, **attributes)
      status = config.fetch("when_denied", "disabled")
      Result.new(**{
        action:,
        status:,
        reason:,
        schema_wrapper: nil,
        edit_affordance: nil,
        domain_command: nil
      }.merge(attributes))
    end

    def unavailable(reason, **attributes)
      Result.new(**{
        action:,
        status: "disabled",
        reason:,
        schema_wrapper: nil,
        edit_affordance: nil,
        domain_command: nil
      }.merge(attributes))
    end
  end
end
