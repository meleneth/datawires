# frozen_string_literal: true

class TightenDomains < ActiveRecord::Migration[8.1]
  def change
    change_column_null :domains, :name, false
    add_index :domains, :name, unique: true
  end
end
