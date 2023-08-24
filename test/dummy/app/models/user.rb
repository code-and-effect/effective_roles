class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  acts_as_role_restricted

  def to_s
    "#{first_name} #{last_name}"
  end

end
