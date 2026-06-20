# frozen_string_literal: true

module Drafts
  class SchemaPropertiesController < ApplicationController
    before_action :set_context

    def add
      SchemaMutations.add_property!(
        @draft.body,
        at: schema_ptr,
        name: params.require(:name),
        type: params.require(:property_type),
        required: truthy?(params[:required])
      )

      update_draft_and_render
    end

    def remove
      SchemaMutations.remove_property!(
        @draft.body,
        at: schema_ptr,
        name: params.require(:name)
      )

      update_draft_and_render
    end

    def rename
      SchemaMutations.rename_property!(
        @draft.body,
        at: schema_ptr,
        old_name: params.require(:old_name),
        new_name: params.require(:new_name)
      )

      update_draft_and_render
    end

    def change_type
      SchemaMutations.change_property_type!(
        @draft.body,
        at: schema_ptr,
        name: params.require(:name),
        type: params.require(:property_type)
      )

      update_draft_and_render
    end

    def set_required
      SchemaMutations.set_required!(
        @draft.body,
        at: schema_ptr,
        name: params.require(:name),
        required: truthy?(params[:required])
      )

      update_draft_and_render
    end

    private

    def set_context
      @draft = Draft.find(params[:draft_id])
      @document = @draft.document
      @domain = @document.domain
    end

    def schema_path
      @schema_path ||= Schemas::Path.new(params[:path].presence || "/")
    end

    def schema_ptr
      schema_path.json_ptr
    end

    def update_draft_and_render
      @draft.save!
      @path = schema_path.to_s
      @diff_rows = Documents::Diff.rows(
        before: @draft.based_on_revision&.body,
        after: @draft.body
      )

      respond_to do |format|
        format.turbo_stream { render :update }
        format.html { redirect_to draft_path(@draft, path: schema_path.to_s) }
      end
    end

    def truthy?(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
