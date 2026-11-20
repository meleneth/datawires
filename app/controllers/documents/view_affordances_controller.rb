# frozen_string_literal: true

module Documents
  class ViewAffordancesController < ApplicationController
    def show
      load_view
      @projection = ViewAffordances::Projection.build(document: @document, view_affordance: @view_affordance)
    end

    def create_related
      load_view
      config = @view_affordance.body.fetch("config")
      raise ArgumentError, "View does not support contextual creation" unless @view_affordance.body["renderer"] == "related_documents"

      schema = @domain.documents.find_by(key: config.fetch("schema_key"))
      schema_wrapper = schema&.schema_wrapper
      raise ArgumentError, "Related document schema was not found" unless schema_wrapper

      decision = Authorization::Policy.call(
        actor: current_actor,
        action: :create_document,
        resource: { schema_wrapper: }
      )
      raise Authorization::NotAuthorized, decision.reason unless decision.allowed?

      document, draft = ::Documents::CreateFromSchema.call(
        schema_wrapper:,
        actor: current_user,
        initial_values: { config.fetch("foreign_key") => @document.key }
      )
      redirect_to draft_path(draft), notice: "Document created."
    rescue ArgumentError, ActiveRecord::RecordInvalid, Authorization::NotAuthorized => error
      redirect_to document_view_affordance_path(@document, @view_affordance), alert: error.message
    end

    private

    def load_view
      @document = Document
        .includes(:domain, :head_revision, schema_document: :schema_wrapper)
        .find(params[:document_id])
      @domain = @document.domain
      require_visible_domain!(@domain)
      @schema_wrapper = @document.schema_record
      @view_affordance = @schema_wrapper.view_affordances.find(params[:id])
    end
  end
end
