class Alexa < ActiveRecord::Base
  belongs_to :user

  validates :alexa_user_id, presence: true, uniqueness: true
  validates :activation_key, uniqueness: true
end
