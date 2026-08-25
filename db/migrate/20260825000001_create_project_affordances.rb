# frozen_string_literal: true

class CreateProjectAffordances < ActiveRecord::Migration[8.1]
  def change
    create_table :project_affordances, id: :uuid do |t|
      t.references :domain, type: :uuid, null: false, foreign_key: true, index: { unique: true }
      t.references :project_document, type: :uuid, null: false, foreign_key: { to_table: :documents }, index: { unique: true }
      t.references :default_board, type: :uuid, foreign_key: { to_table: :boards, on_delete: :nullify }
      t.timestamps
    end
  end
end
