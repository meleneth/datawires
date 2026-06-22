# frozen_string_literal: true

class SchemasController < ApplicationController
  def index
    @domain = Domain.find(params[:domain_id])
    @schemas = SchemaWrapper
      .includes(document: [ :domain, :head_revision ])
      .joins(:document)
      .where(documents: { domain_id: @domain.id })
      .order("documents.key")
  end

  def new
    @domain = Domain.find(params[:domain_id])
    @document = @domain.documents.build
  end

  def create
    @domain = Domain.find(params[:domain_id])

    result = CreateSchemaDocument.call(
      domain: @domain,
      key: schema_params.fetch(:key),
      title: schema_params[:title],
      actor: current_user
    )

    redirect_to draft_path(result.draft)
  end

  def show
    @schema_wrapper = SchemaWrapper
      .includes(
        document: [
          :domain,
          :head_revision,
          { instance_documents: :head_revision }
        ],
        edit_affordances: { edit_document: :head_revision },
        view_affordances: { view_document: :head_revision }
      )
      .find(params[:id])

    @domain = @schema_wrapper.domain
    @documents = @schema_wrapper.conforming_documents
    @edit_affordances = @schema_wrapper.edit_affordances.order(:title)
    @edit_affordance_drafts = Draft
      .where(document_id: @edit_affordances.map(&:edit_document_id), created_by: current_user)
      .index_by(&:document_id)
    @view_affordances = @schema_wrapper.view_affordances.order(:title)
  end

  private

  def schema_params
    params.require(:document).permit(:key, :title)
  end
end
