class User < ActiveRecord::Base
  has_many :stops
  has_many :alexas

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6, maximum: 20 }
end
