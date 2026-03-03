class CreateDrafts < ActiveRecord::Migration[8.1]
  def change
    create_table :drafts, id: :uuid do |t|
      t.references :document, null: false, foreign_key: true, type: :uuid
      t.references :based_on_revision, null: false, foreign_key: true, type: :uuid
      t.jsonb :body
      t.references :created_by, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
