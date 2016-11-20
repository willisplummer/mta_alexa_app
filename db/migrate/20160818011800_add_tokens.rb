class AddTokens < ActiveRecord::Migration
  def change
    create_table :tokens do |t|
      t.string :token_string, unique: true, null: false
      t.boolean :active, default: true, null: false
      t.integer :user_id, null: false
      t.index :user_id

      t.timestamps null: false
    end
  end
end
