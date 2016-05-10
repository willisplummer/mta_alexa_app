class Stop < ActiveRecord::Base
  belongs_to :user


  def make_default
    Stop.where(user_id: user_id, default: true).update_all(default: false)
    self.update(default: true)
  end
end
