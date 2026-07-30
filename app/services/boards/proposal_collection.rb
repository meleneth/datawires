# frozen_string_literal: true

module Boards
  class ProposalCollection
    Result = DocumentCollection::Result

    def self.call(board:, section:)
      new(board:, section:).call
    end

    def initialize(board:, section:)
      raise ArgumentError, "board must be a Board" unless board.is_a?(Board)
      raise ArgumentError, "section must be a Boards::Projection::Entry" unless section.is_a?(Boards::Projection::Entry)

      @board = board
      @section = section
    end

    def call
      schema_wrapper = target_schema_wrapper
      return failure("Schema #{Proposals::Schema::KEY} was not found.") unless schema_wrapper

      proposals = scoped_proposals
        .select { |proposal| states.include?(state_for(proposal)) }
        .sort_by { |proposal| sortable_value(proposal) }
      proposals.reverse! if order.fetch("direction", "asc") == "desc"

      view_affordance = selected_view_affordance(schema_wrapper)
      if config.fetch("navigation", "document") == "view_affordance" && view_affordance.nil?
        return failure("View affordance #{config["view_affordance"]} was not found.")
      end

      Result.new(
        documents: proposals.first(config.fetch("limit", 20)).map(&:proposal_document),
        view_affordance:,
        empty_state:,
        error: nil
      )
    end

    private

    attr_reader :board, :section

    def config
      section.config
    end

    def scoped_proposals
      Proposal
        .includes(proposal_document: [ :head_revision, { schema_document: :schema_wrapper } ])
        .where(proposal_document: { domain_id: board.schema_wrapper.domain.id })
        .to_a
    end

    def target_schema_wrapper
      board.schema_wrapper.domain.documents
        .find_by(key: Proposals::Schema::KEY)
        &.schema_wrapper
    end

    def decided_proposal_ids
      @decided_proposal_ids ||= board.schema_wrapper.domain.documents
        .joins(:schema_document)
        .includes(:head_revision)
        .where(schema_document: { key: Decisions::Schema::KEY })
        .filter_map { |document| document.body.dig("lineage", "proposal_id") }
        .to_set
    end

    def state_for(proposal)
      decided_proposal_ids.include?(proposal.id) ? "decided" : "open"
    end

    def states
      config.fetch("states")
    end

    def order
      config.fetch("order", {})
    end

    def sortable_value(proposal)
      value = case order.fetch("by", "submitted_at")
      when "submitted_at" then proposal.submitted_at
      when "created_at" then proposal.created_at
      when "updated_at" then proposal.updated_at
      end

      [ value.nil? ? 1 : 0, value.to_s, proposal.id ]
    end

    def selected_view_affordance(schema_wrapper)
      return nil unless config["view_affordance"].present?

      schema_wrapper.view_affordances.find_by(title: config["view_affordance"])
    end

    def empty_state
      config["empty_state"].presence || "No proposals found."
    end

    def failure(message)
      Result.new(documents: [], view_affordance: nil, empty_state:, error: message)
    end
  end
end
