# frozen_string_literal: true

class DocumentsController < ApplicationController
  def show
    @document = Document
      .includes(
        :domain,
        :head_revision,
        schema_document: [
          :domain,
          :head_revision,
          {
            schema_wrapper: [
              { edit_affordances: { edit_document: :head_revision } },
              { view_affordances: { view_document: :head_revision } }
            ]
          }
        ]
      )
      .find(params[:id])

    @domain = @document.domain
    @schema_wrapper = @document.schema_document&.schema_wrapper
    @edit_affordances = @schema_wrapper ? @schema_wrapper.edit_affordances : EditAffordance.none
    @view_affordances = @schema_wrapper ? @schema_wrapper.view_affordances : ViewAffordance.none
    @can_apply_roberts_motion = can_apply_roberts_motion?
  end

  private

  def can_apply_roberts_motion?
    return false unless @document.schema_document&.key == "motion"
    return false unless @document.body["status"] == "adopted"
    return false if @document.body["result"].to_s.start_with?("applied")

    RobertsRules::ApplyMotion::SUPPORTED_TYPES.include?(@document.body["motion_type"])
  end
end
