# frozen_string_literal: true

class SchemasController < ApplicationController
  def index
    @domain = Domain.find(params[:domain_id])
    @schemas = @domain.documents.schemas.order(:key)
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
      actor: current_user,
    )

    redirect_to draft_path(result.draft)
  end

  def show
    document = Document
      .includes(
        :domain,
        :head_revision,
        instance_documents: :head_revision
      )
      .find(params[:id])

    @document = SchemaDocument.new(document)
    @domain = @document.domain
    @schema_documents = @document.conforming_documents
  end

  private

  def schema_params
    params.require(:document).permit(:key, :title)
  end
end
