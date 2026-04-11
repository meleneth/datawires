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
          {
            schema_document_record: [
              { edit_affordances: { edit_document: :head_revision } },
              { view_affordances: { view_document: :head_revision } }
            ]
          }
        ]
      )
      .find(params[:id])

    @domain = @document.domain
    @schema_document = @document.schema_document&.schema_document_record
    @edit_affordances = @schema_document ? @schema_document.edit_affordances : EditAffordance.none
    @view_affordances = @schema_document ? @schema_document.view_affordances : ViewAffordance.none
  end
end
