# frozen_string_literal: true

class RequireDraftCreatedBy < ActiveRecord::Migration[8.1]
  def change
    change_column_null :drafts, :created_by_id, false
  end
end
