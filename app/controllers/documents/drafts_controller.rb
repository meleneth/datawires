# app/controllers/documents/drafts_controller.rb
# frozen_string_literal: true

class Documents::DraftsController < ApplicationController
  def create
    document = Document.find(params[:document_id])
    draft = EnsureDraftForDocument.call(document:, actor: try(:current_user))

    redirect_to draft_path(draft, mode: default_mode_for(document), ptr: "/")
  end

  private

  def default_mode_for(document)
    document.schema? ? "schema" : "document"
  end
end

