# frozen_string_literal: true

module Drafts
  class ViewAffordanceBuildersController < ApplicationController
    before_action :load_context

    def show
      @tab = tab_param
    end

    def update_settings
      body = deep_dup_json(@draft.body)
      body["version"] = 1
      body["renderer"] = params[:renderer].presence_in(ViewAffordances::BodyValidator::SUPPORTED_RENDERERS) || "timeline_d3"
      body["title"] = params[:title].to_s
      body["config"] = config_from_params
      @draft.update!(body: body)

      redirect_to draft_view_affordance_builder_path(@draft, tab: "settings"),
        notice: "View settings updated."
    end

    def update_raw
      @draft.update!(body: JSON.parse(params.require(:body_json)))

      redirect_to draft_view_affordance_builder_path(@draft, tab: "raw"),
        notice: "Raw view affordance JSON updated."
    rescue JSON::ParserError => e
      redirect_to draft_view_affordance_builder_path(@draft, tab: "raw"),
        alert: "Invalid JSON: #{e.message}"
    end

    def destroy_affordance
      schema_wrapper = @schema_wrapper
      view_document = @view_affordance.view_document

      ApplicationRecord.transaction do
        @view_affordance.destroy!
        view_document.reload
        view_document.drafts.destroy_all
        view_document.revisions.destroy_all
        view_document.destroy!
      end

      redirect_to schema_path(schema_wrapper),
        notice: "View affordance deleted."
    end

    private

    def load_context
      @draft = Draft.includes(document: :view_affordance).find(params[:draft_id])
      @view_affordance = @draft.document.view_affordance
      raise ActiveRecord::RecordNotFound, "draft is not a view affordance draft" unless @view_affordance

      @schema_wrapper = @view_affordance.schema_wrapper
      @schema_document = @schema_wrapper.document
      @domain = @schema_wrapper.domain
      @schema_options = schema_options
      @diagnostics = ViewAffordances::BodyValidator.new(@draft.body).errors
      @preview_document = preview_document
      @preview_projection = preview_projection
    end

    def tab_param
      params[:tab].presence_in(%w[settings preview diagnostics raw]) || "settings"
    end

    def preview_projection
      return nil unless @preview_document

      ViewAffordances::Projection.build(
        document: @preview_document,
        view_affordance: projection_affordance
      )
    rescue ArgumentError, KeyError => e
      ViewAffordances::Projection.new(
        renderer: "unsupported",
        title: @draft.body["title"].presence || @view_affordance.title,
        data: {
          "message" => e.message,
          "renderer" => @draft.body["renderer"].to_s.presence || "(blank)"
        }
      )
    end

    def projection_affordance
      body = @draft.body
      @projection_affordance ||= ViewAffordance.new(
        schema_wrapper: @schema_wrapper,
        view_document: @draft.document
      ).tap do |affordance|
        affordance.define_singleton_method(:body) { body }
      end
    end

    def config_from_params
      return mud_player_config_from_params if params[:renderer] == "mud_player"
      return mud_choice_player_config_from_params if params[:renderer] == "mud_choice_player"

      config = {
        "schema_key" => params[:schema_key].presence_in(schema_options.map(&:last)) || @schema_wrapper.key,
        "relative_time_label" => params[:relative_time_label].presence || "Relative time"
      }
      participant_kind = params[:participant_kind].presence_in(schema_options.map(&:last))
      config["participant_kind"] = participant_kind if participant_kind.present?
      config["participant_key"] = params[:participant_key].to_s.strip if participant_kind.present? && params[:participant_key].present?
      config
    end

    def mud_player_config_from_params
      schema_keys = schema_options.map(&:last)
      {
        "room_schema_key" => params[:room_schema_key].presence_in(schema_keys) || "mud-room",
        "character_schema_key" => params[:character_schema_key].presence_in(schema_keys) || "mud-character",
        "item_schema_key" => params[:item_schema_key].presence_in(schema_keys) || "mud-item"
      }.tap do |config|
        config["start_room_key"] = params[:start_room_key].to_s.strip if params[:start_room_key].present?
      end
    end

    def mud_choice_player_config_from_params
      schema_keys = schema_options.map(&:last)
      {
        "choice_room_schema_key" => params[:choice_room_schema_key].presence_in(schema_keys) || "mud-choice-room"
      }.tap do |config|
        config["start_room_key"] = params[:start_room_key].to_s.strip if params[:start_room_key].present?
      end
    end

    def deep_dup_json(value)
      Marshal.load(Marshal.dump(value))
    end

    def preview_document
      preview_schema_wrapper&.conforming_documents&.first
    end

    def preview_schema_wrapper
      schema_key = view_config["schema_key"].presence || @schema_wrapper.key
      Document
        .includes(:schema_wrapper)
        .joins(:head_revision)
        .where(domain: @domain, key: schema_key)
        .find_by("revisions.body ->> '$schema' = ?", Document::JSON_SCHEMA_2020_12)
        &.schema_wrapper
    end

    def view_config
      @draft.body["config"].is_a?(Hash) ? @draft.body["config"] : {}
    end

    def schema_options
      @schema_options ||= SchemaWrapper
        .includes(:document)
        .joins(document: :head_revision)
        .where(documents: { domain_id: @domain.id })
        .order("documents.key")
        .map { |wrapper| [ wrapper.document.title.presence || wrapper.key, wrapper.key ] }
    end
  end
end
