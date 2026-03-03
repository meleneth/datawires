class CreateRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :revisions, id: :uuid do |t|
      t.references :document, null: false, foreign_key: true, type: :uuid
      t.references :parent_revision, null: false, foreign_key: true, type: :uuid
      t.jsonb :body
      t.text :message
      t.references :created_by, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
