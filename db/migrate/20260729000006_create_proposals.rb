# frozen_string_literal: true

class CreateProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :proposals, id: :uuid do |t|
      t.references :proposal_document, null: false, type: :uuid, foreign_key: { to_table: :documents }, index: { unique: true }
      t.references :body, null: false, type: :uuid, foreign_key: true
      t.references :submitted_revision, null: false, type: :uuid, foreign_key: { to_table: :revisions }
      t.references :submitted_by, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.datetime :submitted_at, null: false
      t.timestamps
    end
  end
end
