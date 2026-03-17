class AddSchemaDocumentToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_reference :documents,
                  :schema_document,
                  type: :uuid,
                  foreign_key: { to_table: :documents },
                  null: true
  end
end
