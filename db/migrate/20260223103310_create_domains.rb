class CreateDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :domains, id: :uuid do |t|
      t.string :name

      t.timestamps
    end
  end
end
