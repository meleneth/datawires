# frozen_string_literal: true

class DomainCommitsController < ApplicationController
  before_action :set_domain

  def index
    @domain_commits = @domain.domain_commits
      .includes(:parent_domain_commit, :created_by)
      .order(created_at: :desc, id: :desc)
  end

  def show
    @domain_commit = @domain.domain_commits
      .includes(:parent_domain_commit, :created_by)
      .find(params[:id])
    @commit_documents = @domain_commit.domain_commit_documents
      .includes(:document, :revision)
      .order(:document_key)
  end

  private

  def set_domain
    @domain = Domain.find(params.expect(:domain_id))
  end
end
