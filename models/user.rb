class User < ActiveRecord::Base
  has_many :stops, dependent: :destroy
  has_many :alexas, dependent: :destroy
  has_secure_password

  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, allow_nil: true
end
