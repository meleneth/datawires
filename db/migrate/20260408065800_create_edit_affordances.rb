# frozen_string_literal: true

class CreateEditAffordances < ActiveRecord::Migration[8.1]
  def change
    create_table :edit_affordances, id: :uuid do |t|
      t.references :for_schema_document,
        null: false,
        type: :uuid,
        foreign_key: { to_table: :documents },
        index: false

      t.references :affordance_document,
        null: false,
        type: :uuid,
        foreign_key: { to_table: :documents },
        index: false

      t.string :name, null: false

      t.timestamps
    end

    add_index :edit_affordances,
      [ :for_schema_document_id, :name ],
      unique: true,
      name: "index_edit_affordances_on_schema_and_name"

    add_index :edit_affordances,
      :affordance_document_id,
      unique: true
  end
end
