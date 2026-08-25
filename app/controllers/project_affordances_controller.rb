# frozen_string_literal: true

class ProjectAffordancesController < ApplicationController
  def create
    domain = find_visible_domain!(params.expect(:domain_id))
    project = Projects::Install.call(domain:, actor: current_user, title: domain.name, description: "Project workspace")
    redirect_to domain_path(domain), notice: "Project workspace was enabled."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to domain_path(domain), alert: e.record.errors.full_messages.to_sentence
  end
end
