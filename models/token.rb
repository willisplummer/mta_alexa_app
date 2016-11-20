class Token < ActiveRecord::Base
  belongs_to :user

  validates :token_string, presence: true, uniqueness: true, allow_nil: false
end
