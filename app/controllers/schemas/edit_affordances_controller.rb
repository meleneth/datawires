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

    def draft
      schema_wrapper = SchemaWrapper.find(params[:schema_id])
      edit_affordance = schema_wrapper.edit_affordances.find(params[:id])
      draft = edit_affordance.edit_document.draft_for(actor: current_user)

      redirect_to draft_edit_affordance_builder_path(draft),
        notice: "Edit affordance draft opened."
    end
  end
end
