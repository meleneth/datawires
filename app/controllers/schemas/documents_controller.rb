# frozen_string_literal: true

module Schemas
  class DocumentsController < ApplicationController
    def create
      schema_document = SchemaDocument.find(params[:schema_id])

      document, draft = Documents::CreateFromSchema.call(
        schema_document: schema_document,
        actor: current_user
      )

      redirect_params = {}
      redirect_params[:edit_affordance_id] = params[:edit_affordance_id] if params[:edit_affordance_id].present?

      redirect_to draft_path(draft, redirect_params), notice: "Document created."
    end
  end
end
