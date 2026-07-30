# frozen_string_literal: true

class CreateProceduralPolicies < ActiveRecord::Migration[8.1]
  def change
    create_table :procedural_policies, id: :uuid do |t|
      t.references :policy_document, null: false, type: :uuid, foreign_key: { to_table: :documents }, index: { unique: true }
      t.references :body, null: false, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
    add_index :procedural_policies, %i[body_id name], unique: true

    add_reference :meetings, :procedural_policy, type: :uuid, foreign_key: true
  end
end
