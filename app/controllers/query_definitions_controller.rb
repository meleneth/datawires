# frozen_string_literal: true

class QueryDefinitionsController < ApplicationController
  before_action :set_domain

  def index
    @queries = @domain.query_definitions.includes(query_document: :head_revision).order(:key)
  end

  def new
  end

  def create
    query = VersionedDefinitions::Create.call(
      domain: @domain, actor: current_user, schema: Queries::Schema,
      key: query_params.fetch(:key), title: query_params.fetch(:title), wrapper_class: QueryDefinition,
      document_association: :query_document,
      body: {
        "version" => 1, "key" => query_params.fetch(:key), "title" => query_params.fetch(:title),
        "description" => query_params[:description].to_s, "metric_key" => query_params.fetch(:metric_key),
        "aggregate" => query_params.fetch(:aggregate),
        "window_seconds" => positive_integer(query_params[:window_seconds]),
        "bucket_seconds" => positive_integer(query_params[:bucket_seconds])
      }.compact
    )
    redirect_to domain_query_definition_path(@domain, query), notice: "Query definition was created."
  rescue ActiveRecord::RecordInvalid, KeyError => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def show
    @query = @domain.query_definitions.includes(query_document: :head_revision).find(params[:id])
  end

  private

  def set_domain
    @domain = find_visible_domain!(params.expect(:domain_id))
    raise ActiveRecord::RecordNotFound unless @domain.project?
  end

  def query_params
    params.expect(query: %i[key title description metric_key aggregate window_seconds bucket_seconds])
  end

  def positive_integer(value)
    number = value.to_i
    number if number.positive?
  end
end
