require 'test_helper'

class RolesTest < ActiveSupport::TestCase
  test 'user' do
    user = build_user()
    assert user.roles.blank?

    assert user.add_role!(:admin)
    assert user.is?(:admin)

    assert user.remove_role!(:admin)
    refute user.is?(:admin)
  end
end
