# frozen_string_literal: true

class BoardsController < ApplicationController
  def show
    @board = Board.includes(:board_document, schema_wrapper: :document).find(params[:id])
    @schema_wrapper = @board.schema_wrapper
    @domain = @schema_wrapper.domain
    require_visible_domain!(@domain)
    @projection = @board.projection
    @layout_provider = Datawires::Providers.layouts.fetch(@projection.layout_provider)
    @card_results = @projection.columns.flat_map(&:cards).to_h do |card|
      provider = Datawires::Providers.cards.fetch(card.kind)
      result = provider ? provider.new(board: @board, card:, actor: current_actor).call : nil
      [ card.id, result ]
    end
    @sibling_boards = @schema_wrapper.boards.where.not(id: @board.id).order(:title)
    @section_results = @projection.sections.to_h do |section|
      result = case section.kind
      when "document_collection"
        Boards::DocumentCollection.call(board: @board, section:)
      when "meeting_collection"
        Boards::MeetingCollection.call(board: @board, section:)
      when "proposal_collection"
        Boards::ProposalCollection.call(board: @board, section:)
      when "membership_collection"
        Boards::MembershipCollection.call(board: @board, section:, actor: current_actor)
      when "role_assignment_collection"
        Boards::RoleAssignmentCollection.call(board: @board, section:, actor: current_actor)
      end
      [ section.id, result ]
    end
    @action_resolutions = @projection.actions.map do |action|
      Boards::ActionResolution.call(board: @board, action:, actor: current_actor)
    end
  end
end
