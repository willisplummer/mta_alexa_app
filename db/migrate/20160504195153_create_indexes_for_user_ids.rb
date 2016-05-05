class CreateIndexesForUserIds < ActiveRecord::Migration
  def change
    remove_column :alexas, :user_id, :integer
    remove_column :stops, :user_id, :integer
    add_reference :alexas, :user, index: true, foreign_key: true
    add_reference :stops, :user, index: true, foreign_key: true
  end
end
