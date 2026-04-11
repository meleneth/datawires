class CreateDocumentsTables < ActiveRecord::Migration[8.1]
  def change
    create_table :documents, id: :uuid do |t|
      t.references :domain, null: false, foreign_key: true, type: :uuid
      t.string :key, null: false
      t.string :title

      t.timestamps
    end

    create_table :schema_documents, id: :uuid do |t|
      t.references :document,
        null: false,
        type: :uuid,
        foreign_key: true,
        index: false

      t.timestamps
    end

    create_table :edit_affordances, id: :uuid do |t|
      t.references :for_schema_document,
        null: false,
        type: :uuid,
        foreign_key: { to_table: :schema_documents },
        index: false

      t.references :edit_document,
        null: false,
        type: :uuid,
        foreign_key: { to_table: :documents },
        index: false

      t.string :title, null: false

      t.timestamps
    end

    create_table :view_affordances, id: :uuid do |t|
      t.references :for_schema_document,
        null: false,
        type: :uuid,
        foreign_key: { to_table: :schema_documents },
        index: false

      t.references :view_document,
        null: false,
        type: :uuid,
        foreign_key: { to_table: :documents },
        index: false

      t.string :title, null: false

      t.timestamps
    end

    add_index :documents, %i[domain_id key], unique: true
    add_index :schema_documents, :document_id, unique: true

    add_index :edit_affordances,
      [ :for_schema_document_id, :title ],
      unique: true,
      name: "index_edit_affordances_on_schema_and_title"
    add_index :edit_affordances, :edit_document_id

    add_index :view_affordances,
      [ :for_schema_document_id, :title ],
      unique: true,
      name: "index_view_affordances_on_schema_and_title"
    add_index :view_affordances, :view_document_id
  end
end
