class CreateRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :revisions, id: :uuid do |t|
      t.references :document, null: false, foreign_key: true, type: :uuid

      t.references :parent_revision,
                   null: true,
                   foreign_key: { to_table: :revisions },
                   type: :uuid

      t.jsonb :body, null: false
      t.text :message

      t.references :created_by,
                   null: true,
                   foreign_key: { to_table: :users },
                   type: :uuid

      t.timestamps
    end

    add_index :revisions, %i[document_id created_at]
  end
end
