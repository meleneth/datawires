# frozen_string_literal: true

class DraftsController < ApplicationController
  before_action :load_domain
  before_action :load_document
  before_action :load_draft

  def show
    @mode = params[:mode].presence || "document"
    @ptr = normalize_ptr(params[:ptr])
  end

  def patch_ptr
    @mode = params[:mode].presence || "document"
    @ptr = normalize_ptr(params[:ptr])
    value = params[:value]

    @draft.update!(body: JsonPtr.set(@draft.body, @ptr, value))

    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_to domain_document_draft_path(@domain, @document, @draft, mode: @mode, ptr: @ptr)
      end
    end
  rescue KeyError => e
    render plain: e.message, status: :unprocessable_entity
  end

  def publish
    revision = PublishDraft.call(
      draft: @draft,
      message: params.dig(:publish, :message).presence,
      actor: try(:current_user),
    )

    respond_to do |format|
      format.html do
        # pick where you want to land after publish
        redirect_to domain_document_draft_path(@domain, @document, @draft, mode: params[:mode], ptr: params[:ptr]),
                    notice: "Published revision #{revision.id}."
      end

      # If Commit is fired from a turbo-frame submission and you didn't escape to _top,
      # this will at least do something deterministic.
      format.turbo_stream do
        flash.now[:notice] = "Published revision #{revision.id}."
        render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
      end
    end
  rescue PublishDraft::StaleDraftError => e
    respond_to do |format|
      format.html do
        redirect_to domain_document_draft_path(@domain, @document, @draft, mode: params[:mode], ptr: params[:ptr]),
                    alert: e.message
      end
      format.turbo_stream do
        flash.now[:alert] = e.message
        render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash"), status: :conflict
      end
    end
  end

  private

  def load_domain
    @domain = Domain.find(params[:domain_id])
  end

  def load_document
    @document = @domain.documents.find_by!(key: params[:document_key])
  end

  def load_draft
    @draft = @document.drafts.find(params[:id])
  end

  def normalize_ptr(raw)
    JsonPtr::Pointer.parse(raw.to_s).to_s
  rescue ArgumentError
    ""
  end
end
