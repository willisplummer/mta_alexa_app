class CreateAlexaTable < ActiveRecord::Migration
  def change
    create_table :alexas do |t|
      t.string :activation_key
      t.string :alexa_user_id
      t.integer :user_id

    end

    remove_column :users, :alexa_user_id, :string
  end
end
