# frozen_string_literal: true

class DraftsController < ApplicationController
  before_action :load

  def show
    @page = build_show_page(path_param: params[:path].presence || params[:ptr].presence || "/")
  end

  def patch_ptr
    ptr = normalize_ptr(params[:ptr])
    field_cursor = Documents::Cursor.new(source: @draft, path: ptr)
    value = coerce_scalar_value(params[:value], field_cursor.schema_node)

    @draft.update!(body: JsonPtr.set(@draft.body, ptr, value))
    @diff_rows = Documents::Diff.rows(
      before: @draft.based_on_revision&.body,
      after: @draft.body
    )

    respond_to do |format|
      format.turbo_stream
      format.html { head :no_content }
    end
  rescue KeyError => e
    render plain: e.message, status: :unprocessable_entity
  end

  private

  def build_show_page(path_param:)
    cursor = Documents::Cursor.new(
      source: @draft,
      path: path_param
    )

    Drafts::ShowPage.new(
      domain: @domain,
      document: @document,
      draft: @draft,
      cursor: cursor,
      edit_affordance: selected_edit_affordance
    )
  end

  def load
    @draft = Draft.find(params[:id])
    @document = @draft.document
    @domain = @document.domain
  end

  def selected_edit_affordance
    return nil if params[:edit_affordance_id].blank?

    @document
      .edit_affordances_for_schema
      .includes(edit_document: :head_revision)
      .find_by(id: params[:edit_affordance_id])
  end

  def normalize_ptr(raw)
    JsonPtr::Pointer.parse(raw.presence || "/").to_s
  rescue ArgumentError
    "/"
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
