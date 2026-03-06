# frozen_string_literal: true

class Drafts::CommitsController < ApplicationController
  before_action :set_context

  def new
  end

  def create
    PublishDraft.call(
      draft: @draft,
      message: commit_params[:message],
      actor: current_user
    )

    redirect_to domain_path(@domain),
      notice: "Draft committed."
  rescue PublishDraft::StaleDraftError => e
    redirect_to domain_document_draft_path(@domain, @document, @draft),
      alert: e.message
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "Could not commit draft."
    render :new, status: :unprocessable_entity
  end

  private

  def set_context
    @domain = Domain.find(params[:domain_id])
    @document = @domain.documents.find_by!(key: params[:document_key])
    @draft = @document.drafts.find(params[:draft_id])
  end

  def commit_params
    params.require(:commit).permit(:message)
  end
end
