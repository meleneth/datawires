# frozen_string_literal: true

class Schemas::DraftsController < ApplicationController
  def create
    @document = Document.find(params[:schema_id])
    @domain = @document.domain

    draft = @document.drafts.order(created_at: :desc).first

    unless draft
      draft = @document.drafts.create!(
        based_on_revision: @document.head_revision,
        body: deep_dup_json(current_body)
      )
    end

    redirect_to draft_path(draft)
  end

  private

  def current_body
    @document.head_revision&.body || {}
  end

  def deep_dup_json(value)
    Marshal.load(Marshal.dump(value))
  end
end
