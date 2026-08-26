# frozen_string_literal: true

class MetricDefinitionsController < ApplicationController
  before_action :set_domain

  def index
    @metrics = @domain.metric_definitions.includes(metric_document: :head_revision).order(:key)
  end

  def new
  end

  def create
    metric = VersionedDefinitions::Create.call(
      domain: @domain, actor: current_user, schema: Metrics::Schema,
      key: metric_params.fetch(:key), title: metric_params.fetch(:title), wrapper_class: MetricDefinition,
      document_association: :metric_document,
      body: {
        "version" => 1, "key" => metric_params.fetch(:key), "title" => metric_params.fetch(:title),
        "description" => metric_params[:description].to_s,
        "value_type" => metric_params.fetch(:value_type), "unit" => metric_params[:unit].to_s,
        "dimensions" => comma_separated(metric_params[:dimensions]),
        "aggregation" => metric_params.fetch(:aggregation), "correction_policy" => "latest",
        "derived" => derived_definition, "rollup" => rollup_definition
      }.compact
    )
    redirect_to domain_metric_definition_path(@domain, metric), notice: "Metric definition was created."
  rescue ActiveRecord::RecordInvalid, KeyError => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def show
    @metric = @domain.metric_definitions.includes(metric_document: :head_revision).find(params[:id])
  end

  def rollup
    metric = @domain.metric_definitions.includes(metric_document: :head_revision).find(params[:id])
    run = Metrics::Rollup.call(metric_definition: metric, actor: current_user)
    redirect_to domain_metric_definition_path(@domain, metric),
      notice: "Rollup completed with #{run.observation_count} observations."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to domain_metric_definition_path(@domain, metric), alert: e.message
  end

  private

  def set_domain
    @domain = find_visible_domain!(params.expect(:domain_id))
    raise ActiveRecord::RecordNotFound unless @domain.project?
  end

  def metric_params
    params.expect(metric: %i[key title description value_type unit dimensions aggregation derived_operation
      derived_inputs rollup_bucket_seconds])
  end

  def comma_separated(value)
    value.to_s.split(",").map(&:strip).reject(&:blank?).uniq
  end

  def derived_definition
    return if metric_params[:derived_operation].blank?

    { "operation" => metric_params[:derived_operation], "inputs" => comma_separated(metric_params[:derived_inputs]) }
  end

  def rollup_definition
    seconds = metric_params[:rollup_bucket_seconds].to_i
    { "bucket_seconds" => seconds } if seconds.positive?
  end
end
