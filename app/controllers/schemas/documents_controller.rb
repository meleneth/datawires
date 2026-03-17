# frozen_string_literal: true

module Schemas
  class DocumentsController < ApplicationController
    def create
      schema = Document.schemas.find(params[:schema_id])
      document, draft = Documents::CreateFromSchema.call(schema:, actor: current_user)

      redirect_to draft_path(draft), notice: "Document created."
    end
  end
end
