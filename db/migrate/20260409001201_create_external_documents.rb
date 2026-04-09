# frozen_string_literal: true

class CreateExternalDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :external_documents, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :document,
                   null: false,
                   type: :uuid,
                   foreign_key: true,
                   index: { unique: true }

      t.string :canonical_uri, null: false
      t.string :source_uri
      t.string :source_kind, null: false
      t.datetime :imported_at
      t.datetime :last_checked_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :external_documents, :canonical_uri, unique: true
  end
end
