# frozen_string_literal: true

class CreateEventStreamsAndEventRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :event_streams, id: :uuid do |t|
      t.references :domain, null: false, type: :uuid, foreign_key: true
      t.string :stream_type, null: false
      t.uuid :subject_id, null: false
      t.integer :revision, null: false, default: 0
      t.timestamps
    end
    add_index :event_streams, %i[stream_type subject_id], unique: true

    create_table :event_records, id: :uuid do |t|
      t.references :event_stream, null: false, type: :uuid, foreign_key: true
      t.integer :sequence, null: false
      t.string :event_type, null: false
      t.integer :event_version, null: false
      t.jsonb :payload, null: false, default: {}
      t.uuid :command_id, null: false
      t.string :command_type, null: false
      t.integer :command_version, null: false
      t.uuid :correlation_id
      t.uuid :causation_id
      t.references :actor, type: :uuid, foreign_key: { to_table: :users }
      t.datetime :occurred_at, null: false
      t.jsonb :provenance, null: false, default: {}
      t.timestamps
    end
    add_index :event_records, %i[event_stream_id sequence], unique: true
    add_index :event_records, %i[event_stream_id command_id]
    add_index :event_records, %i[event_type event_version]
  end
end
