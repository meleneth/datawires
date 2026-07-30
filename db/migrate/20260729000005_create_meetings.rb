# frozen_string_literal: true

class CreateMeetings < ActiveRecord::Migration[8.1]
  def change
    create_table :meetings, id: :uuid do |t|
      t.references :meeting_document, null: false, type: :uuid, foreign_key: { to_table: :documents }, index: { unique: true }
      t.references :body, null: false, type: :uuid, foreign_key: true
      t.references :event_stream, null: false, type: :uuid, foreign_key: true, index: { unique: true }
      t.timestamps
    end
  end
end
