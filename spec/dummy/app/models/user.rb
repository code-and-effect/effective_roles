class User < ActiveRecord::Base
  acts_as_role_restricted
end
