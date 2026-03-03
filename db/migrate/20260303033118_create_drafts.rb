class CreateDrafts < ActiveRecord::Migration[8.1]
  def change
    create_table :drafts, id: :uuid do |t|
      t.references :document, null: false, foreign_key: true, type: :uuid

      t.references :based_on_revision,
                   null: true,
                   foreign_key: { to_table: :revisions },
                   type: :uuid


      t.jsonb :body, null: false, default: {}


      t.references :created_by,
                   null: true,
                   foreign_key: { to_table: :users },
                   type: :uuid

      t.timestamps
    end

    add_index :drafts, %i[document_id created_by_id], unique: true
  end
end
