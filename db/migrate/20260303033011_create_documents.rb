class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents, id: :uuid do |t|
      t.references :domain, null: false, foreign_key: true, type: :uuid
      t.string :key, null: false
      t.string :title

      t.timestamps
    end

    add_index :documents, %i[domain_id key], unique: true
  end
end
