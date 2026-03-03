# frozen_string_literal: true

class DraftsController < ApplicationController
  before_action :load_domain
  before_action :load_document
  before_action :load_draft

  def show
    @ptr = normalize_ptr(params[:ptr])
    @value = JsonPtr.get(@draft.body, @ptr)
  end

  # Accepts { ptr: "/title", value: "New Title" }
  # Updates draft.body immutably and re-renders the ribbon + editor frame.
  def patch_ptr
    ptr = normalize_ptr(params[:ptr])
    value = params[:value]

    @draft.update!(body: JsonPtr.set(@draft.body, ptr, value))

    @ptr = ptr
    @value = JsonPtr.get(@draft.body, @ptr)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to domain_document_draft_path(@domain, @document, @draft, ptr: @ptr) }
    end
  rescue KeyError => e
    # v1: no autovivify. If user tries to set a missing parent path, surface nicely.
    render plain: e.message, status: :unprocessable_entity
  end

  private

  def load_domain
    @domain = Domain.find_by!(slug: params[:domain_slug])
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
