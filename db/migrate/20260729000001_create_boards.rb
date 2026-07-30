# frozen_string_literal: true

class CreateBoards < ActiveRecord::Migration[8.1]
  def change
    create_table :boards, id: :uuid do |t|
      t.references :schema_wrapper, null: false, type: :uuid, foreign_key: true
      t.references :board_document,
                   null: false,
                   type: :uuid,
                   foreign_key: { to_table: :documents },
                   index: { unique: true }
      t.string :title, null: false
      t.boolean :public, null: false, default: false

      t.timestamps
    end

    add_index :boards, %i[schema_wrapper_id title], unique: true
    add_reference :schema_wrappers,
                  :default_board,
                  type: :uuid,
                  foreign_key: { to_table: :boards, on_delete: :nullify }
  end
end
