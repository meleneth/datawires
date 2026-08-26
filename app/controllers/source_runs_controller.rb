# frozen_string_literal: true

class SourceRunsController < ApplicationController
  def create
    source = Source.includes(:domain).find(params[:source_id])
    require_visible_domain!(source.domain)
    Sources::ExecuteJob.perform_later(source.id, trigger: "manual", actor_id: current_user.id)
    redirect_to domain_source_path(source.domain, source), notice: "Source run was queued."
  end
end
