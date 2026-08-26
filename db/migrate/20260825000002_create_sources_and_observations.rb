# frozen_string_literal: true

class CreateSourcesAndObservations < ActiveRecord::Migration[8.1]
  def change
    create_table :source_credentials, id: :uuid do |t|
      t.references :domain, type: :uuid, null: false, foreign_key: true
      t.string :name, null: false
      t.text :encrypted_payload, null: false
      t.timestamps
      t.index %i[domain_id name], unique: true
    end

    create_table :sources, id: :uuid do |t|
      t.references :domain, type: :uuid, null: false, foreign_key: true
      t.references :source_document, type: :uuid, null: false, foreign_key: { to_table: :documents }, index: { unique: true }
      t.references :source_credential, type: :uuid, foreign_key: true
      t.boolean :enabled, null: false, default: true
      t.string :status, null: false, default: "idle"
      t.datetime :next_run_at
      t.datetime :last_started_at
      t.datetime :last_succeeded_at
      t.datetime :last_failed_at
      t.text :last_error
      t.timestamps
      t.index %i[enabled next_run_at]
    end

    create_table :source_runs, id: :uuid do |t|
      t.references :source, type: :uuid, null: false, foreign_key: true
      t.references :configuration_revision, type: :uuid, null: false, foreign_key: { to_table: :revisions }
      t.references :triggered_by, type: :uuid, foreign_key: { to_table: :users }
      t.string :trigger, null: false
      t.string :adapter, null: false
      t.string :adapter_version, null: false
      t.string :status, null: false, default: "pending"
      t.integer :attempt, null: false, default: 1
      t.string :idempotency_key, null: false
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :observation_count, null: false, default: 0
      t.string :error_class
      t.text :error_message
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
      t.index %i[source_id idempotency_key], unique: true
    end

    create_table :observations, id: :uuid do |t|
      t.references :domain, type: :uuid, null: false, foreign_key: true
      t.references :source, type: :uuid, null: false, foreign_key: true
      t.references :source_run, type: :uuid, null: false, foreign_key: true
      t.references :configuration_revision, type: :uuid, null: false, foreign_key: { to_table: :revisions }
      t.references :corrects_observation, type: :uuid, foreign_key: { to_table: :observations }
      t.string :observation_type, null: false
      t.string :metric_key
      t.string :unit
      t.decimal :numeric_value
      t.jsonb :dimensions, null: false, default: {}
      t.jsonb :payload, null: false, default: {}
      t.jsonb :provenance, null: false, default: {}
      t.datetime :observed_at, null: false
      t.datetime :effective_at, null: false
      t.datetime :recorded_at, null: false
      t.string :correction_kind
      t.timestamps
      t.index %i[source_id observed_at]
      t.index %i[metric_key observed_at]
      t.index :dimensions, using: :gin
    end
  end
end
