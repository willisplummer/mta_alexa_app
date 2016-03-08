class CreateUser < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string :user_id
    end
  end

  def down
    drop_table :users
  end
end
