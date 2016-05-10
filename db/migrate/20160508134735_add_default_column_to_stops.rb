class AddDefaultColumnToStops < ActiveRecord::Migration
  def change
    add_column :stops, :default, :boolean, null: false, default: false
  end
end
