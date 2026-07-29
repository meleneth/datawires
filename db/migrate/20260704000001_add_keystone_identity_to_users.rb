# frozen_string_literal: true

class AddKeystoneIdentityToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :external_id, :string
    add_column :users, :email, :string

    add_index :users, :external_id, unique: true
    add_index :users, :email
  end
end
