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
            schema_wrapper: [
              { edit_affordances: { edit_document: :head_revision } },
              { view_affordances: { view_document: :head_revision } }
            ]
          }
        ]
      )
      .find(params[:id])

    @domain = @document.domain
    @schema_wrapper = @document.schema_document&.schema_wrapper
    @edit_affordances = @schema_wrapper ? @schema_wrapper.edit_affordances : EditAffordance.none
    @view_affordances = @schema_wrapper ? @schema_wrapper.view_affordances : ViewAffordance.none
  end
end
