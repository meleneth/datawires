# frozen_string_literal: true

class ProjectBoardsController < ApplicationController
  def create
    domain = find_visible_domain!(params.expect(:domain_id))
    project = domain.project_affordance || raise(ActiveRecord::RecordNotFound)
    result = CreateBoard.call(
      schema_wrapper: project.project_document.schema_document.schema_wrapper,
      title: params[:title].presence || "Project Board",
      actor: current_user,
      definition: {
        "version" => 1, "title" => "Project Board", "description" => "",
        "layout" => { "provider" => "kanban" }, "columns" => [], "sections" => [], "actions" => []
      }
    )
    project.update!(default_board: result.board) if project.default_board.nil?
    redirect_to board_path(result.board), notice: "Project board was created."
  end
end
