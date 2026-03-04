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
