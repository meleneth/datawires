# frozen_string_literal: true

module Boards
  class ActionsController < ApplicationController
    def create
      board = Board.includes(schema_wrapper: :document).find(params[:board_id])
      require_visible_domain!(board.schema_wrapper.domain)
      action = board.projection.actions.find { |candidate| candidate.id == params[:id] }
      raise ActiveRecord::RecordNotFound unless action

      resolution = Boards::ActionResolution.call(board:, action:, actor: current_actor)
      unless resolution.available?
        return redirect_to board_path(board), alert: resolution.reason
      end

      document, draft = Documents::CreateFromSchema.call(
        schema_wrapper: resolution.schema_wrapper,
        actor: current_user
      )
      redirect_to draft_path(
        draft,
        edit_affordance_id: resolution.edit_affordance&.id
      ), notice: "Document created."
    end
  end
end
