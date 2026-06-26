# frozen_string_literal: true

module Drafts
  class ViewAffordanceBuildersController < ApplicationController
    before_action :load_context

    def show
      @tab = tab_param
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
      @diagnostics = ViewAffordances::BodyValidator.new(@draft.body).errors
      @preview_document = @schema_wrapper.conforming_documents.first
      @preview_projection = preview_projection
    end

    def tab_param
      params[:tab].presence_in(%w[preview diagnostics raw]) || "preview"
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
  end
end
