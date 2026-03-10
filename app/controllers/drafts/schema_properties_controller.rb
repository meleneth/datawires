# frozen_string_literal: true

class Drafts::SchemaPropertiesController < ApplicationController
  before_action :load

  def add
    SchemaMutations.add_property!(
      @draft.body,
      at: raw_ptr,
      name: params[:name],
      type: params[:property_type],
      required: boolean_param(:required),
    )

    persist_and_render
  end

  def remove
    SchemaMutations.remove_property!(
      @draft.body,
      at: raw_ptr,
      name: params[:name],
    )

    persist_and_render
  end

  def rename
    SchemaMutations.rename_property!(
      @draft.body,
      at: raw_ptr,
      old_name: params[:old_name],
      new_name: params[:new_name],
    )

    persist_and_render
  end

  def change_type
    SchemaMutations.change_property_type!(
      @draft.body,
      at: raw_ptr,
      name: params[:name],
      type: params[:property_type],
    )

    persist_and_render
  end

  def set_required
    SchemaMutations.set_required!(
      @draft.body,
      at: raw_ptr,
      name: params[:name],
      required: boolean_param(:required),
    )

    persist_and_render
  end

  private

  def load
    @draft = Draft.find(params[:draft_id])
    @document = @draft.document
    @domain = @document.domain
    @path = SchemaPath.normalize(params[:path])
  end

  def raw_ptr
    SchemaPath.new(@path).json_ptr
  end

  def boolean_param(name)
    ActiveModel::Type::Boolean.new.cast(params[name])
  end

  def persist_and_render
    @draft.save!

    respond_to do |format|
      format.turbo_stream { render "drafts/patch_ptr" }
      format.html { redirect_to draft_path(@draft, path: @path) }
    end
  rescue KeyError, ArgumentError => e
    render plain: e.message, status: :unprocessable_entity
  end
end
