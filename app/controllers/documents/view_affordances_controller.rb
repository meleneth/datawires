# frozen_string_literal: true

module Documents
  class ViewAffordancesController < ApplicationController
    def show
      @document = Document
        .includes(:domain, :head_revision, schema_document: :schema_wrapper)
        .find(params[:document_id])
      @domain = @document.domain
      @schema_wrapper = @document.schema_record
      @view_affordance = @schema_wrapper.view_affordances.find(params[:id])
      @projection = ViewAffordances::Projection.build(document: @document, view_affordance: @view_affordance)
    end
  end
end
