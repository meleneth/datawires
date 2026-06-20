# frozen_string_literal: true

class Drafts::CommitsController < ApplicationController
  before_action :set_context

  def new
    @preflight = DraftCommitPreflight.new(draft: @draft)
  end

  def create
    @preflight = DraftCommitPreflight.new(
      draft: @draft,
      confirmed_warning_codes: commit_params[:confirmed_warnings]
    )

    if @preflight.blocked?
      flash.now[:alert] = "Confirm the commit warnings to continue."
      render :new, status: :unprocessable_entity
      return
    end

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
    params.require(:commit).permit(:message, confirmed_warnings: [])
  end
end
