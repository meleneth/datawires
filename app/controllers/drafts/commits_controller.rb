# frozen_string_literal: true

class Drafts::CommitsController < ApplicationController
  before_action :set_context

  def new
    @preflight = DraftCommitPreflight.new(draft: @draft)
    @diff_rows = draft_diff_rows
  end

  def create
    @preflight = DraftCommitPreflight.new(
      draft: @draft,
      confirmed_warning_codes: commit_params[:confirmed_warnings]
    )

    if @preflight.blocked?
      @diff_rows = draft_diff_rows
      flash.now[:alert] = "Confirm the commit warnings to continue."
      render :new, status: :unprocessable_entity
      return
    end

    PublishDraft.call(
      draft: @draft,
      message: commit_params[:message],
      actor: current_user
    )

    redirect_to document_path(@document),
      notice: "Draft committed."
  rescue PublishDraft::StaleDraftError => e
    redirect_to draft_path(@draft),
      alert: e.message
  rescue ActiveRecord::RecordInvalid
    @diff_rows = draft_diff_rows
    flash.now[:alert] = "Could not commit draft."
    render :new, status: :unprocessable_entity
  end

  private

  def set_context
    @draft = Draft.find(params[:draft_id])
    @document = @draft.document
    @domain = @document.domain
    @path = params[:path].presence
    @screen = params[:screen].presence
    @edit_affordance_id = params[:edit_affordance_id].presence
  end

  def commit_params
    params.require(:commit).permit(:message, confirmed_warnings: [])
  end

  def draft_diff_rows
    Documents::Diff.rows(
      before: @draft.based_on_revision&.body,
      after: @draft.body
    )
  end
end
