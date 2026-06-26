# frozen_string_literal: true

module Schemas
  class ViewAffordancesController < ApplicationController
    def create
      schema_wrapper = SchemaWrapper.find(params[:schema_id])
      result = CreateViewAffordance.call(
        schema_wrapper: schema_wrapper,
        title: params[:title],
        actor: current_user
      )

      redirect_to draft_view_affordance_builder_path(result.draft),
        notice: "View affordance created."
    end

    def draft
      schema_wrapper = SchemaWrapper.find(params[:schema_id])
      view_affordance = schema_wrapper.view_affordances.find(params[:id])
      draft = view_affordance.view_document.draft_for(actor: current_user)

      redirect_to draft_view_affordance_builder_path(draft),
        notice: "View affordance draft opened."
    end
  end
end
