# frozen_string_literal: true

module Schemas
  class EditAffordancesController < ApplicationController
    def create
      schema_wrapper = SchemaWrapper.find(params[:schema_id])
      result = CreateEditAffordance.call(
        schema_wrapper: schema_wrapper,
        title: params[:title],
        actor: current_user
      )

      redirect_to draft_edit_affordance_builder_path(result.draft),
        notice: "Edit affordance created."
    end
  end
end
