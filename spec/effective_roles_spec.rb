require 'spec_helper'

describe EffectiveRoles do
  let(:roles) { [:superadmin, :admin, :member] }

  let(:post) { Post.new }
  let(:user) { User.new.tap { |user| user.roles = [] } }

  let(:member) { User.new.tap { |user| user.roles = [:member] } }
  let(:admin) { User.new.tap { |user| user.roles = [:admin] } }
  let(:superadmin) { User.new.tap { |user| user.roles = [:superadmin] } }

  before(:each) do
    EffectiveRoles.setup { |config| config.roles = roles }
  end

  describe '#roles_for_roles_mask' do
    it 'computes the appropriate roles for the given mask' do
      EffectiveRoles.roles_for_roles_mask(nil).should eq []
      EffectiveRoles.roles_for_roles_mask(0).should eq []
      EffectiveRoles.roles_for_roles_mask(1).should eq [:superadmin]
      EffectiveRoles.roles_for_roles_mask(2).should eq [:admin]
      EffectiveRoles.roles_for_roles_mask(3).should eq [:superadmin, :admin]
      EffectiveRoles.roles_for_roles_mask(4).should eq [:member]
      EffectiveRoles.roles_for_roles_mask(5).should eq [:superadmin, :member]
      EffectiveRoles.roles_for_roles_mask(6).should eq [:admin, :member]
      EffectiveRoles.roles_for_roles_mask(7).should eq [:superadmin, :admin, :member]
      EffectiveRoles.roles_for_roles_mask(8).should eq []
    end
  end

  describe '#assignable_roles' do
    it 'uses the full Hash syntax to return the appropriate roles based on the passed User' do
      EffectiveRoles.setup do |config|
        config.assignable_roles = {
          'User' => {
            :superadmin => [:superadmin, :admin, :member], # Superadmins may assign all roles on a User#edit screen
            :admin => [:admin, :member],                   # Admins may only assign :admin, :member on a User#edit screen
            :member => []                                  # Members can assign no roles
          },
          'Post' => {
            :superadmin => [:superadmin],                   # Superadmins may assign ony superadmin on a Post#edit screen
            :admin => [:superadmin, :admin],
            :member => [:admin, :member]
          }
        }
      end

      # On a User#edit screen
      EffectiveRoles.assignable_roles_for(nil, user).should eq [:superadmin, :admin, :member]
      EffectiveRoles.assignable_roles_for(superadmin, user).should eq [:superadmin, :admin, :member]
      EffectiveRoles.assignable_roles_for(admin, user).should eq [:admin, :member]
      EffectiveRoles.assignable_roles_for(member, user).should eq []
      EffectiveRoles.assignable_roles_for(user, user).should eq []

      # On a Post#edit screen
      EffectiveRoles.assignable_roles_for(nil, post).should eq [:superadmin, :admin, :member]
      EffectiveRoles.assignable_roles_for(superadmin, post).should eq [:superadmin]
      EffectiveRoles.assignable_roles_for(admin, post).should eq [:superadmin, :admin]
      EffectiveRoles.assignable_roles_for(member, post).should eq [:admin, :member]
      EffectiveRoles.assignable_roles_for(user, post).should eq []

      # On an unsupported object #edit screen
      EffectiveRoles.assignable_roles_for(nil, nil).should eq [:superadmin, :admin, :member]
      EffectiveRoles.assignable_roles_for(superadmin, nil).should eq []
      EffectiveRoles.assignable_roles_for(admin, nil).should eq []
      EffectiveRoles.assignable_roles_for(member, nil).should eq []
      EffectiveRoles.assignable_roles_for(user, nil).should eq []
    end

    it 'uses the simple Hash syntax to return the appropriate roles based on the passed User' do
      EffectiveRoles.setup do |config|
        config.assignable_roles = {
          :superadmin => [:superadmin, :admin, :member], # Superadmins may assign any resource any role
          :admin => [:admin, :member],                   # Admins may only assign the :admin or :member role
          :member => []                                  # Members may not assign any roles
        }
      end

      EffectiveRoles.assignable_roles_for(nil).should eq [:superadmin, :admin, :member]

      EffectiveRoles.assignable_roles_for(superadmin).should eq [:superadmin, :admin, :member]
      EffectiveRoles.assignable_roles_for(admin).should eq [:admin, :member]
      EffectiveRoles.assignable_roles_for(member).should eq []
      EffectiveRoles.assignable_roles_for(user).should eq []
    end

    it 'uses the Array syntax to return the appropriate roles based on the passed User' do
      EffectiveRoles.setup do |config|
        config.assignable_roles = [:admin, :member]
      end

      EffectiveRoles.assignable_roles_for(nil).should eq [:admin, :member]
      EffectiveRoles.assignable_roles_for(superadmin).should eq [:admin, :member]
      EffectiveRoles.assignable_roles_for(admin).should eq [:admin, :member]
      EffectiveRoles.assignable_roles_for(member).should eq [:admin, :member]
      EffectiveRoles.assignable_roles_for(user).should eq [:admin, :member]
    end

    it 'uses the Nil syntax to return all roles regardless of User' do
      EffectiveRoles.setup do |config|
        config.assignable_roles = nil
      end

      EffectiveRoles.assignable_roles_for(nil).should eq roles
      EffectiveRoles.assignable_roles_for(superadmin).should eq roles
      EffectiveRoles.assignable_roles_for(admin).should eq roles
      EffectiveRoles.assignable_roles_for(member).should eq roles
      EffectiveRoles.assignable_roles_for(user).should eq roles
    end

  end

  describe '#disabled_roles' do
    it 'uses the full Hash syntax to return the appropriate roles based on the passed User' do
      EffectiveRoles.setup do |config|
        config.disabled_roles = {
          'User' => [:member],
          'Post' => [:superadmin],
        }
      end

      # On a User#edit screen
      EffectiveRoles.disabled_roles_for(user).should eq [:member]
      EffectiveRoles.disabled_roles_for(post).should eq [:superadmin]
      EffectiveRoles.disabled_roles_for(nil).should eq []
    end

    it 'uses the lazy Hash syntax to return the appropriate roles based on the passed User' do
      EffectiveRoles.setup do |config|
        config.disabled_roles = {
          'User' => :member,
          'Post' => :superadmin,
        }
      end

      # On a User#edit screen
      EffectiveRoles.disabled_roles_for(user).should eq [:member]
      EffectiveRoles.disabled_roles_for(post).should eq [:superadmin]
      EffectiveRoles.disabled_roles_for(nil).should eq []
    end

  end



end
