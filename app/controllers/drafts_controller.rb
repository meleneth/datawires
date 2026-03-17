# frozen_string_literal: true

class DraftsController < ApplicationController
  before_action :load

  def show
    if @draft.schema_document?
      @path = SchemaPath.new(params[:path])
    else
      @path = DocumentPath.new(params[:path] || params[:ptr])
      @projection = DocumentProjection.new(source: @draft, path: @path)
      @value = @projection.document_node
      @schema_node = @projection.schema_node || {}
      @properties = @schema_node.fetch("properties", {})
      @property_rows = @projection.child_rows
    end
  end

  def patch_ptr
    @ptr = normalize_ptr(params[:ptr])
    value = params[:value]

    @draft.update!(body: JsonPtr.set(@draft.body, @ptr, value))

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to draft_path(@draft, ptr: @ptr) }
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
        redirect_to schema_document_redirect_target,
                    notice: "Published revision #{revision.id}."
      end

      format.turbo_stream do
        flash.now[:notice] = "Published revision #{revision.id}."
        render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
      end
    end
  rescue PublishDraft::StaleDraftError => e
    respond_to do |format|
      format.html do
        redirect_to draft_redirect_target_on_error, alert: e.message
      end
      format.turbo_stream do
        flash.now[:alert] = e.message
        render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash"), status: :conflict
      end
    end
  end

  private

  def load
    @draft = Draft.find(params[:id])
    @document = @draft.document
    @domain = @document.domain
  end

  def normalize_ptr(raw)
    JsonPtr::Pointer.parse(raw.presence || "/").to_s
  rescue ArgumentError
    "/"
  end

  def schema_document_redirect_target
    if @document.schema_document?
      schema_path(@document)
    else
      domain_document_path(@domain, @document)
    end
  end

  def draft_redirect_target_on_error
    if @document.schema_document?
      draft_path(@draft, path: SchemaPath.normalize(params[:path]))
    else
      draft_path(@draft, ptr: normalize_ptr(params[:ptr]))
    end
  end
end
