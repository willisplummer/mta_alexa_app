class CreateStop < ActiveRecord::Migration
  def up
    create_table :stops do |t|
      t.string :name
      t.integer :mta_stop_id
      t.integer :time_to_stop
    end
  end

  def down
    drop_table :stops
  end
end
