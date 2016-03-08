class CreateUser < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string :userID
    end
  end

  def down
    drop_table :users
  end
end
