class Addtimestamps < ActiveRecord::Migration
  def change
    add_timestamps(:users)
    add_timestamps(:alexas)
    add_timestamps(:stops)

    User.where(created_at: nil).update_all(created_at: Time.now)
    User.where(updated_at: nil).update_all(updated_at: Time.now)

    Alexa.where(created_at: nil).update_all(created_at: Time.now)
    Alexa.where(updated_at: nil).update_all(updated_at: Time.now)

    Stop.where(created_at: nil).update_all(created_at: Time.now)
    Stop.where(updated_at: nil).update_all(updated_at: Time.now)

    change_column_null :users, :created_at, false
    change_column_null :users, :updated_at, false

    change_column_null :alexas, :created_at, false
    change_column_null :alexas, :updated_at, false

    change_column_null :stops, :created_at, false
    change_column_null :stops, :updated_at, false
  end
end
