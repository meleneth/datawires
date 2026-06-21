# frozen_string_literal: true

class DraftsController < ApplicationController
  before_action :load

  def show
    @page = build_show_page(path_param: params[:path].presence || params[:ptr].presence || "")
  end

  def patch_ptr
    ptr = normalize_ptr(params[:ptr])
    field_cursor = Documents::Cursor.new(source: @draft, path: ptr)
    value = coerce_scalar_value(params[:value], field_cursor.schema_node)

    @draft.update!(body: set_json_ptr_value(@draft.body, ptr, value))
    @diff_rows = Documents::Diff.rows(
      before: @draft.based_on_revision&.body,
      after: @draft.body
    )

    respond_to do |format|
      format.turbo_stream { head :no_content }
      format.html { head :no_content }
    end
  rescue KeyError => e
    render plain: e.message, status: :unprocessable_entity
  end

  def add_item
    ptr = normalize_ptr(params[:ptr])
    array_cursor = Documents::Cursor.new(source: @draft, path: ptr)

    unless array_cursor.array?
      render plain: "target is not an array", status: :unprocessable_entity
      return
    end

    updated_array = Array(array_cursor.value) + [ array_cursor.seed_item_value ]
    item_path = array_cursor.path.child(updated_array.length - 1).to_s
    @draft.update!(body: JsonPtr.set(@draft.body, ptr, updated_array))
    @page = build_show_page(path_param: item_path)

    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_to draft_path(
          @draft,
          path: item_path,
          edit_affordance_id: params[:edit_affordance_id]
        )
      end
    end
  rescue KeyError => e
    render plain: e.message, status: :unprocessable_entity
  end

  def destroy
    shell_document = @document if @document.head_revision.nil?

    @draft.destroy!
    shell_document.destroy! if shell_document && shell_document.drafts.reload.empty?

    redirect_to domain_path(@domain), notice: "Draft discarded."
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
    schema_wrapper = @document.schema_record
    return nil unless schema_wrapper

    return EditAffordances::Generated.new(schema_wrapper:) if params[:edit_affordance_id].blank?

    @document
      .edit_affordances_for_schema
      .includes(edit_document: :head_revision)
      .find_by(id: params[:edit_affordance_id]) ||
      EditAffordances::Generated.new(schema_wrapper:)
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

  def set_json_ptr_value(body, ptr, value)
    seeded_body = ensure_parent_paths(body, ptr)
    JsonPtr.set(seeded_body, ptr, value)
  end

  def ensure_parent_paths(body, ptr)
    pointer = JsonPtr::Pointer.parse(ptr)
    return body if pointer.root?

    seeded_body = body
    parent_tokens = pointer.tokens[0...-1]

    parent_tokens.each_with_index do |token, index|
      parent_ptr = JsonPtr::Pointer.new(parent_tokens[0..index])
      existing = JsonPtr.fetch(seeded_body, parent_ptr, default: JsonPtr::UNDEFINED)
      next unless existing == JsonPtr::UNDEFINED

      next_token = parent_tokens[index + 1]&.unescaped || pointer.tokens.last.unescaped
      seed_value = array_index_token?(next_token) ? [] : {}
      seeded_body = JsonPtr.set(seeded_body, parent_ptr, seed_value)
    end

    seeded_body
  end

  def array_index_token?(token)
    token.to_s.match?(/\A\d+\z/)
  end
end
