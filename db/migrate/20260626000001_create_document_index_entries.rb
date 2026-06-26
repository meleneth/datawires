# frozen_string_literal: true

class CreateDocumentIndexEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :document_index_entries, id: :uuid do |t|
      t.references :document, null: false, type: :uuid, foreign_key: true
      t.references :revision, null: false, type: :uuid, foreign_key: true
      t.references :schema_document, null: false, type: :uuid, foreign_key: { to_table: :documents }
      t.string :index_type, null: false
      t.string :key
      t.text :value
      t.string :label
      t.jsonb :metadata, null: false, default: {}
      t.timestamps

      t.index [ :document_id, :revision_id, :index_type, :key ],
        name: "index_document_index_entries_for_rebuild"
      t.index [ :schema_document_id, :index_type ],
        name: "index_document_index_entries_on_schema_and_type"
      t.index [ :schema_document_id, :index_type, :value ],
        name: "index_document_index_entries_on_schema_type_value"
      t.index [ :schema_document_id, :index_type, :label ],
        name: "index_document_index_entries_on_schema_type_label"
    end
  end
end
