# frozen_string_literal: true

class AddSourceExecutionLeases < ActiveRecord::Migration[8.1]
  def change
    add_column :sources, :lease_token, :string
    add_column :sources, :leased_until, :datetime
    add_index :sources, :leased_until
  end
end
