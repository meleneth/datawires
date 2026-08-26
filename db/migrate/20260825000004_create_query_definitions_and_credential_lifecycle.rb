# frozen_string_literal: true

class CreateQueryDefinitionsAndCredentialLifecycle < ActiveRecord::Migration[8.1]
  def change
    create_table :query_definitions, id: :uuid do |t|
      t.references :domain, null: false, foreign_key: true, type: :uuid
      t.references :query_document, null: false, foreign_key: { to_table: :documents }, type: :uuid,
        index: { unique: true }
      t.string :key, null: false
      t.timestamps
    end
    add_index :query_definitions, %i[domain_id key], unique: true
    add_column :source_credentials, :rotated_at, :datetime
    add_column :source_credentials, :revoked_at, :datetime
  end
end
