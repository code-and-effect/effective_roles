require 'spec_helper'

describe EffectiveRoles do
  let(:roles) { [:superadmin, :admin, :member] }
  let(:user) { User.new.tap { |user| user.roles = [] } }
  let(:member) { User.new.tap { |user| user.roles = [:member] } }
  let(:admin) { User.new.tap { |user| user.roles = [:admin] } }
  let(:superadmin) { User.new.tap { |user| user.roles = [:superadmin] } }

  before(:each) do
    EffectiveRoles.setup { |config| config.roles = roles }
  end

  describe '#roles_for_roles_mask' do
    it 'returns the appropriate roles' do
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
    before(:each) do
      EffectiveRoles.setup do |config|
        config.assignable_roles = {
          :superadmin => [:superadmin, :admin, :member], # Superadmins may assign any resource any role
          :admin => [:admin, :member],                   # Admins may only assign the :admin or :member role
          :member => []                                  # Members may not assign any roles
        }
      end
    end

    it 'returns the appropriate roles based on the User passed' do
      EffectiveRoles.assignable_roles_for(nil).should eq roles

      EffectiveRoles.assignable_roles_for(user).should eq roles
      EffectiveRoles.assignable_roles_for(superadmin).should eq [:superadmin, :admin, :member]
      EffectiveRoles.assignable_roles_for(admin).should eq [:admin, :member]
      EffectiveRoles.assignable_roles_for(member).should eq []
    end

  end


end
