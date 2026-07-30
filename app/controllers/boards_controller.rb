# frozen_string_literal: true

class BoardsController < ApplicationController
  def show
    @board = Board.includes(:board_document, schema_wrapper: :document).find(params[:id])
    @schema_wrapper = @board.schema_wrapper
    @domain = @schema_wrapper.domain
    require_visible_domain!(@domain)
    @projection = @board.projection
  end
end
