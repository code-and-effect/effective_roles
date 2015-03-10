describe 'Acts As Role Restricted' do
  let(:roles) { [:superadmin, :admin, :member] }

  let(:user) { User.new.tap { |user| user.roles = [] } }
  let(:member) { User.new.tap { |user| user.roles = [:member] } }
  let(:admin) { User.new.tap { |user| user.roles = [:admin] } }
  let(:superadmin) { User.new.tap { |user| user.roles = [:superadmin] } }
  let(:member_and_admin) { User.new.tap { |user| user.roles = [:member, :admin] } }

  before(:each) do
    EffectiveRoles.setup { |config| config.roles = roles }
  end

  describe '#is_any?(roles)' do
    context 'when subject has one of the roles in question' do
      let(:post) { Post.new.tap { |post| post.roles = [:member] } }

      it 'is true' do
        post.is_any?(:admin, :member).should be(true)
      end
    end

    context 'when subject does not have any of the roles in question' do
      let(:post) { Post.new.tap { |post| post.roles = [:member] } }

      it 'is false' do
        post.is_any?(:admin, :superadmin).should be(false)
      end
    end

    context 'when subject does not have any roles' do
      let(:post) { Post.new }

      it 'is false' do
        post.is_any?(:member, :admin, :superadmin).should be(false)
      end
    end
  end

  describe '#roles_permit?(obj)' do
    describe 'when subject has no roles' do
      let(:post) { Post.new }

      it 'should be true when passed nil' do
        post.roles_permit?(nil).should eq true
      end

      it 'should be true for any user' do
        post.roles_permit?(user).should eq true
        post.roles_permit?(member).should eq true
        post.roles_permit?(admin).should eq true
        post.roles_permit?(superadmin).should eq true
      end
    end

    describe 'when subject has one role' do
      let(:post) { Post.new.tap { |post| post.roles = [:member] } }

      it 'should be false when passed nil' do
        post.roles_permit?(nil).should eq false
      end

      it 'should be false when passed object doesnt share roles' do
        post.roles_permit?(user).should eq false
        post.roles_permit?(admin).should eq false
        post.roles_permit?(superadmin).should eq false
      end

      it 'should be true for a user with all the same roles' do
        post.roles_permit?(member).should eq true
        post.roles_permit?(member_and_admin).should eq true
      end
    end

    describe 'when subject has multiple roles' do
      let(:post) { Post.new.tap { |post| post.roles = [:member, :admin] } }

      it 'should be false when passed nil' do
        post.roles_permit?(nil).should eq false
      end

      it 'should be false when passed object doesnt share all roles' do
        post.roles_permit?(user).should eq false
        post.roles_permit?(superadmin).should eq false
      end

      it 'should be true for a user with overlapping roles' do
        post.roles_permit?(member).should eq true
        post.roles_permit?(admin).should eq true
        post.roles_permit?(member_and_admin).should eq true
      end
    end
  end

  describe '#roles_overlap?(obj)' do
    describe 'when subject has no roles' do
      let(:post) { Post.new }

      it 'should be true when passed nil' do
        post.roles_overlap?(nil).should eq true
      end

      it 'should be true when user has no roles either' do
        post.roles_overlap?(user).should eq true
      end

      it 'should be false for any user with roles' do
        post.roles_overlap?(member).should eq false
        post.roles_overlap?(admin).should eq false
        post.roles_overlap?(superadmin).should eq false
      end
    end

    describe 'when subject has one role' do
      let(:post) { Post.new.tap { |post| post.roles = [:member] } }

      it 'should be false when passed nil' do
        post.roles_overlap?(nil).should eq false
      end

      it 'should be false when passed object doesnt share roles' do
        post.roles_overlap?(user).should eq false
        post.roles_overlap?(admin).should eq false
        post.roles_overlap?(superadmin).should eq false
      end

      it 'should be true for a user with all the same roles' do
        post.roles_overlap?(member).should eq true
        post.roles_overlap?(member_and_admin).should eq true
      end
    end

    describe 'when subject has multiple roles' do
      let(:post) { Post.new.tap { |post| post.roles = [:member, :admin] } }

      it 'should be false when passed nil' do
        post.roles_overlap?(nil).should eq false
      end

      it 'should be false when passed object doesnt share all roles' do
        post.roles_overlap?(user).should eq false
        post.roles_overlap?(superadmin).should eq false
      end

      it 'should be true for a user with overlapping roles' do
        post.roles_overlap?(member).should eq true
        post.roles_overlap?(admin).should eq true
        post.roles_overlap?(member_and_admin).should eq true
      end
    end
  end


  describe '#roles_match?(obj)' do
    describe 'when subject has no roles' do
      let(:post) { Post.new }

      it 'should be true when passed nil' do
        post.roles_match?(nil).should eq true
      end

      it 'should be true when user has no roles either' do
        post.roles_match?(user).should eq true
      end

      it 'should be false for any user with roles' do
        post.roles_match?(member).should eq false
        post.roles_match?(admin).should eq false
        post.roles_match?(superadmin).should eq false
      end
    end

    describe 'when subject has one role' do
      let(:post) { Post.new.tap { |post| post.roles = [:member] } }

      it 'should be false when passed nil' do
        post.roles_match?(nil).should eq false
      end

      it 'should be false when passed object doesnt share roles' do
        post.roles_match?(user).should eq false
        post.roles_match?(admin).should eq false
        post.roles_match?(superadmin).should eq false
      end

      it 'should be true for a user with all the same roles' do
        post.roles_match?(member).should eq true
      end

      it 'should be false when the user has more roles' do
        post.roles_match?(member_and_admin).should eq false
      end
    end

    describe 'when subject has multiple roles' do
      let(:post) { Post.new.tap { |post| post.roles = [:member, :admin] } }

      it 'should be false when passed nil' do
        post.roles_match?(nil).should eq false
      end

      it 'should be false when passed object doesnt share all roles' do
        post.roles_match?(user).should eq false
        post.roles_match?(superadmin).should eq false
        post.roles_match?(member).should eq false
        post.roles_match?(admin).should eq false
      end

      it 'should be true for a user with same roles' do
        post.roles_match?(member_and_admin).should eq true
      end
    end
  end




end
