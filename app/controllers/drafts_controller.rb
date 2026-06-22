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

    next_body = if optional_blank_value?(value, field_cursor)
      delete_json_ptr_value(@draft.body, ptr)
    else
      set_json_ptr_value(@draft.body, ptr, value)
    end

    @draft.update!(body: next_body)
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
          screen: screen_id_param,
          edit_affordance_id: params[:edit_affordance_id]
        )
      end
    end
  rescue KeyError => e
    render plain: e.message, status: :unprocessable_entity
  end

  def remove_item
    ptr = normalize_ptr(params[:ptr])
    index = Integer(params[:index], 10)
    array_cursor = Documents::Cursor.new(source: @draft, path: ptr)

    unless array_cursor.array?
      render plain: "target is not an array", status: :unprocessable_entity
      return
    end

    updated_array = Array(array_cursor.value).dup
    unless index >= 0 && index < updated_array.length
      render plain: "item index is out of range", status: :unprocessable_entity
      return
    end

    updated_array.delete_at(index)
    @draft.update!(body: JsonPtr.set(@draft.body, ptr, updated_array))
    @page = build_show_page(path_param: cursor_path_after_collection_mutation(array_cursor.path))

    respond_to do |format|
      format.turbo_stream { render :add_item }
      format.html do
        redirect_to draft_path(
          @draft,
          path: @page.cursor.path.to_s,
          edit_affordance_id: params[:edit_affordance_id]
        )
      end
    end
  rescue ArgumentError, KeyError => e
    render plain: e.message, status: :unprocessable_entity
  end

  def reorder_item
    ptr = normalize_ptr(params[:ptr])
    index = Integer(params[:index], 10)
    direction = params[:direction].to_s
    array_cursor = Documents::Cursor.new(source: @draft, path: ptr)

    unless array_cursor.array?
      render plain: "target is not an array", status: :unprocessable_entity
      return
    end

    updated_array = Array(array_cursor.value).dup
    target_index = reorder_target_index(index, direction)

    unless target_index && index >= 0 && index < updated_array.length && target_index >= 0 && target_index < updated_array.length
      render plain: "item cannot be moved #{direction}", status: :unprocessable_entity
      return
    end

    updated_array[index], updated_array[target_index] = updated_array[target_index], updated_array[index]
    @draft.update!(body: JsonPtr.set(@draft.body, ptr, updated_array))
    @page = build_show_page(path_param: cursor_path_after_collection_mutation(array_cursor.path))

    respond_to do |format|
      format.turbo_stream { render :add_item }
      format.html do
        redirect_to draft_path(
          @draft,
          path: @page.cursor.path.to_s,
          edit_affordance_id: params[:edit_affordance_id]
        )
      end
    end
  rescue ArgumentError, KeyError => e
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
      screen_id: screen_id_param,
      edit_affordance: selected_edit_affordance
    )
  end

  def screen_id_param
    params[:screen].presence || params[:collection_item_screen].presence
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

  def cursor_path_after_collection_mutation(array_path)
    requested_path = params[:path].presence
    if requested_path.present?
      requested_documents_path = Documents::Path.new(requested_path)
      return requested_path unless path_within?(root_path: array_path, candidate_path: requested_documents_path)
    end

    array_path.to_s
  rescue Documents::Path::InvalidPathError
    array_path.to_s
  end

  def path_within?(root_path:, candidate_path:)
    root_tokens = root_path.tokens
    candidate_tokens = candidate_path.tokens

    candidate_tokens.first(root_tokens.length) == root_tokens
  end

  def reorder_target_index(index, direction)
    case direction
    when "up"
      index - 1
    when "down"
      index + 1
    end
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

  def delete_json_ptr_value(body, ptr)
    pointer = JsonPtr::Pointer.parse(ptr)
    return body if pointer.root?

    tokens = pointer.tokens
    parent_ptr = JsonPtr::Pointer.new(tokens[0...-1])
    parent_value = JsonPtr.fetch(body, parent_ptr, default: JsonPtr::UNDEFINED)
    return body if parent_value == JsonPtr::UNDEFINED

    updated_parent = delete_from_container(parent_value, tokens.last.unescaped)
    next_body = parent_ptr.root? ? updated_parent : JsonPtr.set(body, parent_ptr, updated_parent)

    prune_empty_parent_containers(next_body, tokens)
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

  def optional_blank_value?(value, field_cursor)
    return false if field_cursor.required?

    value.nil? || (value.is_a?(String) && value.strip.empty?)
  end

  def delete_from_container(container, token)
    case container
    when Hash
      dup = container.dup
      if dup.key?(token)
        dup.delete(token)
      else
        symbolized = safe_to_sym(token)
        dup.delete(symbolized) if symbolized && dup.key?(symbolized)
      end
      dup
    when Array
      idx = Integer(token, 10)
      dup = container.dup
      dup.delete_at(idx) if idx >= 0 && idx < dup.length
      dup
    else
      container
    end
  rescue ArgumentError, TypeError
    container
  end

  def prune_empty_parent_containers(body, tokens)
    pruned_body = body

    (tokens.length - 1).downto(1) do |depth|
      node_ptr = JsonPtr::Pointer.new(tokens[0...depth])
      node_value = JsonPtr.fetch(pruned_body, node_ptr, default: JsonPtr::UNDEFINED)
      break unless node_value.is_a?(Hash) && node_value.empty?

      ancestor_ptr = JsonPtr::Pointer.new(tokens[0...(depth - 1)])
      ancestor_value = JsonPtr.fetch(pruned_body, ancestor_ptr, default: JsonPtr::UNDEFINED)
      break if ancestor_value == JsonPtr::UNDEFINED

      updated_ancestor = delete_from_container(ancestor_value, tokens[depth - 1].unescaped)
      pruned_body = ancestor_ptr.root? ? updated_ancestor : JsonPtr.set(pruned_body, ancestor_ptr, updated_ancestor)
    end

    pruned_body
  end

  def safe_to_sym(token)
    return nil unless token.is_a?(String)
    return nil if token.empty? || token.bytesize > 200
    return nil unless token.match?(/\A[a-zA-Z_][a-zA-Z0-9_]*[!?=]?\z/)

    token.to_sym
  end
end
