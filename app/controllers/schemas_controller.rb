# app/controllers/schemas_controller.rb
# frozen_string_literal: true

class SchemasController < ApplicationController
  def index
    @domain = Domain.find_by!(slug: params[:domain_slug] || params[:domain_id])
    @schemas = @domain.documents.schemas.order(:key)
  end

  def new
    @domain = Domain.find_by!(slug: params[:domain_slug] || params[:domain_id])
    @document = @domain.documents.build
  end

  def create
    @domain = Domain.find_by!(slug: params[:domain_slug] || params[:domain_id])

    result = CreateSchemaDocument.call(
      domain: @domain,
      key: schema_params.fetch(:key),
      title: schema_params[:title],
      actor: current_user
    )

    redirect_to domain_document_draft_path(
      @domain,
      result.document,
      result.draft
    )
  end

  private

  def schema_params
    params.require(:document).permit(:key, :title)
  end
end
