class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents, id: :uuid do |t|
      t.references :domain, null: false, foreign_key: true, type: :uuid
      t.string :key
      t.string :title
      t.references :head_revision, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
