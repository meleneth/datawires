# frozen_string_literal: true

class DraftsController < ApplicationController
  before_action :load

  def show
    load_document_editor_state(params[:path] || params[:ptr])
  end

  def patch_ptr
    @ptr = normalize_ptr(params[:ptr])
    render_path = params[:path].presence || "/"
    field_path = Documents::Path.new(@ptr)

    projection = Documents::Projection.new(
      source: @draft,
      path: field_path,
      edit_affordance: selected_edit_affordance_body
    )

    schema_node = projection.schema_node || {}
    value = coerce_scalar_value(params[:value], schema_node)

    @draft.update!(body: JsonPtr.set(@draft.body, @ptr, value))

    load_document_editor_state(render_path)

    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_to draft_path(
          @draft,
          path: render_path,
          edit_affordance_id: params[:edit_affordance_id]
        )
      end
    end
  rescue KeyError => e
    render plain: e.message, status: :unprocessable_entity
  end

  private

  def load_document_editor_state(path_param = nil)
    if @draft.schema_document?
      @path = Schemas::Path.new(path_param)
      return
    end

    @path = Documents::Path.new(path_param || params[:ptr])
    @projection = Documents::Projection.new(
      source: @draft,
      path: @path,
      edit_affordance: selected_edit_affordance_body
    )
    @value = @projection.document_node
    @schema_node = @projection.schema_node || {}
    @properties = @schema_node.fetch("properties", {})
    @editor_rows = @projection.editor_rows

    @diff_rows = Documents::Diff.rows(
      before: @draft.based_on_revision&.body,
      after: @draft.body
    )
  end

  def load
    @draft = Draft.find(params[:id])
    @document = @draft.document
    @domain = @document.domain
  end

  def selected_edit_affordance_body
    return nil if params[:edit_affordance_id].blank?
    return nil unless @document.schema_document

    @document.schema_document
      .edit_affordances_for_schema
      .includes(edit_document: :head_revision)
      .find_by(id: params[:edit_affordance_id])
      &.edit_document
      &.body
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
      document_path(@document)
    end
  end

  def draft_redirect_target_on_error
    if @document.schema_document?
      draft_path(
        @draft,
        path: Schemas::Path.normalize(params[:path]),
        edit_affordance_id: params[:edit_affordance_id]
      )
    else
      draft_path(
        @draft,
        ptr: normalize_ptr(params[:ptr]),
        edit_affordance_id: params[:edit_affordance_id]
      )
    end
  end

  def coerce_scalar_value(raw, schema_node)
    return raw if schema_node.blank?

    if schema_node["enum"].present?
      return nil if raw.blank?
      return raw
    end

    case schema_node["type"]
    when "boolean"
      ActiveModel::Type::Boolean.new.cast(raw)
    when "integer"
      return nil if raw.blank?
      Integer(raw, 10)
    when "number"
      return nil if raw.blank?
      Float(raw)
    else
      raw
    end
  rescue ArgumentError, TypeError
    raw
  end
end
