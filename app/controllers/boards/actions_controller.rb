# frozen_string_literal: true

module Boards
  class ActionsController < ApplicationController
    def new
      load_action
      @resolution = resolve_action
      return redirect_to board_path(@board), alert: @resolution.reason unless @resolution.available?
      return redirect_to board_path(@board), alert: "This action does not have a command form." unless @resolution.domain_command

      @fields = @resolution.domain_command.fields
    end

    def create
      load_action
      resolution = resolve_action
      unless resolution.available?
        return redirect_to board_path(@board), alert: resolution.reason
      end

      if resolution.domain_command
        result = resolution.domain_command.call(command_parameters(resolution.domain_command))
        return redirect_to result.location, notice: result.notice
      end

      document, draft = Documents::CreateFromSchema.call(
        schema_wrapper: resolution.schema_wrapper,
        actor: current_user
      )
      redirect_to draft_path(
        draft,
        edit_affordance_id: resolution.edit_affordance&.id
      ), notice: "Document created."
    rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing, ArgumentError, Authorization::NotAuthorized => error
      redirect_to board_path(@board), alert: error.message
    end

    private

    def load_action
      @board = Board.includes(schema_wrapper: :document).find(params[:board_id])
      require_visible_domain!(@board.schema_wrapper.domain)
      @action = @board.projection.actions.find { |candidate| candidate.id == params[:id] }
      raise ActiveRecord::RecordNotFound unless @action
    end

    def resolve_action
      Boards::ActionResolution.call(board: @board, action: @action, actor: current_actor)
    end

    def command_parameters(command)
      field_names = command.fields.map(&:name)
      params.fetch(:command, {}).permit(*field_names).to_h.symbolize_keys
    end
  end
end
