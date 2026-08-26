# frozen_string_literal: true

class CreateMetricDefinitions < ActiveRecord::Migration[8.1]
  def change
    create_table :metric_definitions, id: :uuid do |t|
      t.references :domain, type: :uuid, null: false, foreign_key: true
      t.references :metric_document, type: :uuid, null: false, foreign_key: { to_table: :documents }, index: { unique: true }
      t.string :key, null: false
      t.timestamps
      t.index %i[domain_id key], unique: true
    end
  end
end
