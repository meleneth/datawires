# frozen_string_literal: true

class DocumentsController < ApplicationController
  def show
    @document = Document
      .includes(
        :domain,
        :head_revision,
        schema_document: [
          :domain,
          :head_revision,
          { edit_affordances_for_schema: { affordance_document: :head_revision } },
          { render_views_for_schema: { view_document: :head_revision } }
        ]
      )
      .find(params[:id])

    @domain = @document.domain
    @schema_document = @document.schema_document && SchemaDocument.new(@document.schema_document)
    @edit_affordances = @schema_document ? @schema_document.edit_affordances : EditAffordance.none
    @render_views = @schema_document ? @schema_document.render_views : RenderView.none
  end
end
