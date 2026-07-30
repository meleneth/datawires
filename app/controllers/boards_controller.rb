# frozen_string_literal: true

class BoardsController < ApplicationController
  def show
    @board = Board.includes(:board_document, schema_wrapper: :document).find(params[:id])
    @schema_wrapper = @board.schema_wrapper
    @domain = @schema_wrapper.domain
    require_visible_domain!(@domain)
    @projection = @board.projection
    @section_results = @projection.sections.to_h do |section|
      result = if section.kind == "document_collection"
        Boards::DocumentCollection.call(board: @board, section:)
      end
      [ section.id, result ]
    end
    @action_resolutions = @projection.actions.map do |action|
      Boards::ActionResolution.call(board: @board, action:, actor: current_actor)
    end
  end
end
