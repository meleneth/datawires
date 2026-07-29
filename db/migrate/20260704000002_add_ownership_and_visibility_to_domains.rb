# frozen_string_literal: true

class AddOwnershipAndVisibilityToDomains < ActiveRecord::Migration[8.1]
  def change
    add_reference :domains, :owner, type: :uuid, foreign_key: { to_table: :users }
    add_column :domains, :public, :boolean, default: false, null: false

    add_index :domains, :public
    add_index :domains, %i[owner_id public]
  end
end
