require 'test_helper'

class RolesTest < ActiveSupport::TestCase
  test 'user' do
    user = build_user()
    assert user.roles.blank?

    assert user.add_role!(:admin)
    assert user.is?(:admin)

    assert user.add_role!(:member)
    assert user.is?(:admin)
    assert user.is?(:member)

    assert user.remove_role!(:admin)
    refute user.is?(:admin)
    assert user.is?(:member)
  end

  test 'roles_badges' do
    assert_equal :primary, EffectiveRoles.color(:superadmin)
    assert_equal :secondary, EffectiveRoles.color(:admin)
    assert_nil EffectiveRoles.color(:member)
  end

end
