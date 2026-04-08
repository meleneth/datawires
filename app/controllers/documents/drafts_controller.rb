# frozen_string_literal: true

class Documents::DraftsController < ApplicationController
  def create
    document = Document.find(params[:document_id])
    draft = EnsureDraftForDocument.call(document:, actor: current_user)

    redirect_to draft_path(draft, redirect_params(document))
  end

  private

  def redirect_params(document)
    base_params = {
      edit_affordance_id: params[:edit_affordance_id]
    }

    if document.schema_document?
      base_params.merge(path: "/")
    else
      base_params.merge(ptr: "/")
    end
  end
end
