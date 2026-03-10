# frozen_string_literal: true

class DraftsController < ApplicationController
  before_action :load

  def show
    @ptr = normalize_ptr(params[:ptr])
  end

  def patch_ptr
    @ptr = normalize_ptr(params[:ptr])
    value = params[:value]

    @draft.update!(body: JsonPtr.set(@draft.body, @ptr, value))

    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_to draft_path(@draft, mode: @mode, ptr: @ptr)
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
        redirect_to draft_path(@draft, mode: params[:mode], ptr: params[:ptr]),
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
        redirect_to draft_path(@draft, mode: params[:mode], ptr: params[:ptr]),
                    alert: e.message
      end
      format.turbo_stream do
        flash.now[:alert] = e.message
        render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash"), status: :conflict
      end
    end
  end

  private

  def load
    @draft = Draft.find params[:id]
    @document = @draft.document
    @domain = @document.domain
  end

  def default_mode
    @document.schema_document? ? "schema" : "document"
  end

  def normalize_ptr(raw)
    JsonPtr::Pointer.parse(raw.to_s).to_s
  rescue ArgumentError
    "/"
  end
end
