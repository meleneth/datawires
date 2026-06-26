# frozen_string_literal: true

class CreateDomainCommits < ActiveRecord::Migration[8.1]
  def change
    add_column :domains, :repository_mode, :boolean, null: false, default: false

    create_table :domain_commits, id: :uuid do |t|
      t.references :domain, null: false, type: :uuid, foreign_key: true
      t.references :parent_domain_commit, type: :uuid, foreign_key: { to_table: :domain_commits }
      t.references :created_by, type: :uuid, foreign_key: { to_table: :users }
      t.text :message
      t.string :state_hash, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps

      t.index [ :domain_id, :state_hash ], unique: true
    end

    create_table :domain_commit_documents, id: :uuid do |t|
      t.references :domain_commit, null: false, type: :uuid, foreign_key: true
      t.references :document, null: false, type: :uuid, foreign_key: true
      t.references :revision, null: false, type: :uuid, foreign_key: true
      t.string :document_key
      t.string :revision_hash, null: false
      t.timestamps

      t.index [ :domain_commit_id, :document_id ], unique: true
      t.index [ :document_id, :revision_id ]
    end

    add_reference :domains, :head_domain_commit, type: :uuid, foreign_key: { to_table: :domain_commits }
  end
end
