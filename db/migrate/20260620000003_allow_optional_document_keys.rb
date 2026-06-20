# frozen_string_literal: true

class AllowOptionalDocumentKeys < ActiveRecord::Migration[8.1]
  def up
    change_column_null :documents, :key, true
  end

  def down
    change_column_null :documents, :key, false
  end
end
