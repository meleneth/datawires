# frozen_string_literal: true

class Documents::MotionApplicationsController < ApplicationController
  def create
    document = Document.find(params.expect(:document_id))
    RobertsRules::ApplyMotion.call(motion_document: document, actor: current_user)
    redirect_to document_path(document), notice: "Motion was applied."
  rescue RobertsRules::ApplyMotion::Error => e
    redirect_to document_path(document), alert: e.message
  end
end
