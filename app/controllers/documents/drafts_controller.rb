# frozen_string_literal: true

class Documents::DraftsController < ApplicationController
  def create
    document = Document.find(params[:document_id])
    draft = EnsureDraftForDocument.call(document:, actor: current_user)

    return redirect_to draft_path(draft, path: "/") if document.schema_document?
    redirect_to draft_path(draft, ptr: "/")
  end
end
