# frozen_string_literal: true

class Documents::DraftsController < ApplicationController
  def create
    document = Document.find(params[:document_id])
    draft = EnsureDraftForDocument.call(document:, actor: current_user)

    redirect_to draft_path(draft, ptr: "/")
  end
end
