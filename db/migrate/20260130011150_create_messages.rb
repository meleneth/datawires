class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages, id: :uuid do |t|
      t.references :room, null: false, foreign_key: true, type: :uuid
      t.text :content

      t.timestamps
    end
  end
end
