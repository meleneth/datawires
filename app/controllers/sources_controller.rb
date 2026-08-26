# frozen_string_literal: true

class SourcesController < ApplicationController
  before_action :set_domain

  def index
    @sources = @domain.sources.includes(:source_credential, source_document: :head_revision).order(:created_at)
  end

  def new
  end

  def create
    source = Sources::Create.call(
      domain: @domain,
      actor: current_user,
      title: source_params.fetch(:title),
      adapter: "http_json",
      config: { "url" => source_params.fetch(:url), "method" => "GET" },
      schedule: schedule_params,
      observation: observation_params
    )
    redirect_to domain_sources_path(@domain), notice: "Source was created."
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def show
    @source = @domain.sources.includes(:source_credential, source_document: :head_revision).find(params[:id])
    @runs = @source.source_runs.includes(:configuration_revision).order(created_at: :desc).limit(20)
  end

  private

  def set_domain
    @domain = find_visible_domain!(params.expect(:domain_id))
  end

  def source_params
    params.expect(source: %i[title url every_seconds metric_key unit value_pointer observed_at_pointer])
  end

  def schedule_params
    seconds = source_params[:every_seconds].to_i
    seconds.positive? ? { "every_seconds" => seconds } : nil
  end

  def observation_params
    {
      "type" => "metric",
      "metric_key" => source_params[:metric_key].presence,
      "unit" => source_params[:unit].presence,
      "value_pointer" => source_params[:value_pointer].presence,
      "observed_at_pointer" => source_params[:observed_at_pointer].presence
    }.compact
  end
end
