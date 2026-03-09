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
    redirect_to draft_path(@draft),
      alert: e.message
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "Could not commit draft."
    render :new, status: :unprocessable_entity
  end

  private

  def set_context
    @draft = Draft.find(params[:draft_id])
    @document = @draft.document
    @domain = @document.domain
  end

  def commit_params
    params.require(:commit).permit(:message)
  end
end
