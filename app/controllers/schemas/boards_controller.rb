# frozen_string_literal: true

module Schemas
  class BoardsController < ApplicationController
    def create
      schema_wrapper = SchemaWrapper.find(params[:schema_id])
      require_visible_domain!(schema_wrapper.domain)
      result = CreateBoard.call(
        schema_wrapper:,
        title: params[:title],
        actor: current_user
      )

      redirect_to board_path(result.board), notice: "Board created."
    end
  end
end
