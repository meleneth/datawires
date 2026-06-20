# frozen_string_literal: true

module Documents
  class DraftsController < ApplicationController
    def create
      document = Document.find(params[:document_id])
      draft = document.draft_for(actor: current_user)

      redirect_params = {}
      redirect_params[:edit_affordance_id] = params[:edit_affordance_id] if params[:edit_affordance_id].present?

      redirect_to draft_path(draft, redirect_params)
    end
  end
end
