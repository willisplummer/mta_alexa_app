class User < ActiveRecord::Base
  has_many :stops, dependent: :destroy
end
