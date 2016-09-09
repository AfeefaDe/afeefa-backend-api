require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context 'As user' do
    setup do
      @user = create(:user)
    end

    should 'have some basic attributes not nil' do
      assert @user.respond_to? :password
      assert @user.has_attribute? :email

    end

    should 'have some basic attributes' do
      assert @user.has_attribute? :forename
      assert @user.has_attribute? :surname
    end

    should 'have orgas' do
      orga = create(:orga)
      role = build(:role, orga: orga, user: @user)
      @user.roles << role
      assert_equal 1, @user.reload.orgas.size
      assert_equal orga, @user.orgas.first
    end

    should 'have contact information' do
      skip 'needs to be implemented'
    end

    should 'have role for orga' do
      assert orga = create(:orga)
      assert @user.save
      role = Role.new(title: Role::ORGA_ADMIN, orga: orga, user: @user)
      assert role.save

      assert @user.reload.orga_admin?(orga)
      assert !@user.reload.orga_member?(orga)
    end

    should 'be owner of things' do
      event = nil
      assert_difference('Event.count') do
        event = create(:event)
      end

      assert_difference('@user.reload.events.count') do
        assert_difference('@user.owner_thing_relations.count') do
          assert_difference('OwnerThingRelation.count') do
            OwnerThingRelation.create(ownable: event, thingable: @user)
          end
        end
      end
    end

    should 'be creator of things' do
      assert_difference('@user.created_events.count') do
        event = create(:event, creator: @user)
        assert_equal @user, event.creator
      end
    end

    should 'I want to update my data to keep it up to date' do
      assert_no_difference('User.count') do
        new_forename = @user.forename+'123'
        new_surname = @user.surname+'123'
        assert_not_equal new_forename, @user.forename
        assert_not_equal new_surname, @user.surname
        @user.update(forename: new_forename, surname: new_surname)
        assert_equal new_forename, @user.forename
        assert_equal new_surname, @user.surname
      end
    end

    should 'I must not add an existing user to any orga' do
      another_orga = create(:another_orga)
      assert_no_difference('another_orga.users.count') do
        assert_raise CanCan::AccessDenied do
          another_orga.add_new_member(new_member: create(:another_user), admin: @user)
        end
      end
    end
  end

  context 'As member' do
    setup do
      @member = create(:member, orga: build(:orga))
      @my_orga = @member.orgas.first
    end

    should 'I must not add a new user to an orga' do
      @my_orga.expects(:add_new_member).never

      assert_no_difference('User.count') do
        assert_raise CanCan::AccessDenied do
          @member.create_user_and_add_to_orga(email: 'foo@afeefa.de', forename: 'Afeefa', surname: 'Team', orga: @my_orga)
        end
      end
    end

    should 'I must not add an existing user to any orga' do
      new_user = create(:user)

      assert_no_difference('@my_orga.users.count') do
        assert_raise CanCan::AccessDenied do
          @my_orga.add_new_member(new_member: new_user, admin: @member)
        end
      end

      another_orga = create(:another_orga)
      assert_no_difference('another_orga.users.count') do
        assert_raise CanCan::AccessDenied do
          another_orga.add_new_member(new_member: new_user, admin: @member)
        end
      end
    end

    should 'I want to leave an orga' do
      assert_difference('@my_orga.users.count', -1) do
        @member.leave_orga(orga: @my_orga)
      end
      refute(@member.orga_member?(@my_orga))
    end

    should 'I want to leave an orga, I am not in orga' do
      assert_raise ActiveRecord::RecordNotFound do
        assert_no_difference('@my_orga.roles.count') do
          @member.leave_orga(orga: build(:orga))
        end
      end
    end

  end

  context 'As admin' do
    setup do
      @admin = create(:admin)
      @my_orga = @admin.orgas.first
    end

    should 'I want to create a new user to add it to my orga' do
      @my_orga.expects(:add_new_member).once
      User.expects(:create!).once

      @admin.create_user_and_add_to_orga(email: 'team@afeefa.de', forename: 'Afeefa', surname: 'Team', orga: @my_orga)
    end

    context 'interacting with an user' do
      setup do
        @user = create(:user)
      end

      should 'I want to add an existing user to my orga' do
        assert_difference('@my_orga.users.count') do
          @my_orga.add_new_member(new_member: @user, admin: @admin)
        end

        assert @user.orga_member?(@my_orga)
      end

      context 'interacting with a member' do
        setup do
          @member = create(:member, orga: @my_orga)
        end

        should 'I must not add a member to my orga again' do
          assert @member.orga_member?(@my_orga)
          assert_raise UserIsAlreadyMemberException do
            assert_no_difference('@my_orga.users.count') do
              @my_orga.add_new_member(new_member: @member, admin: @admin)
            end
          end

        end

        should 'I want to remove a user from an orga. i am not admin' do
          assert_raise CanCan::AccessDenied do
            assert_no_difference('@my_orga.users.count') do
              @user.remove_user_from_orga(member: @member, orga: @my_orga)
            end
          end
        end

        should 'I want to remove a user from an orga. user is in orga' do
          assert_difference('@my_orga.users.count', -1) do
            @admin.remove_user_from_orga(member: @member, orga: @my_orga)
          end
          refute(@member.orga_member?(@my_orga) || @member.orga_admin?(@my_orga))
        end

        should 'I want to remove a user from an orga. user is not in orga' do
          assert_raise ActiveRecord::RecordNotFound do
            assert_no_difference('@my_orga.roles.count') do
              @admin.remove_user_from_orga(member: @user, orga: @my_orga)
            end
          end
        end

        should 'I want to promote a member to admin, user not in orga' do
          assert_raise ActiveRecord::RecordNotFound do
            @admin.promote_member_to_admin(member: @user, orga: @my_orga)
          end
        end

        should 'I want to promote a member to admin, i am not admin' do
          assert_raise CanCan::AccessDenied do
            @user.promote_member_to_admin(member: @member, orga: @my_orga)
          end
        end

        should 'I want to promote a member to admin' do
          assert_no_difference('@my_orga.roles.count') do
            @admin.promote_member_to_admin(member: @member, orga: @my_orga)
            assert_equal Role.find_by(orga: @my_orga, user: @member).title, Role::ORGA_ADMIN
          end
        end

        should 'I want to demote an admin to member, user not in orga' do
          assert_raise ActiveRecord::RecordNotFound do
            @admin.demote_admin_to_member(member: @user, orga: @my_orga)
          end
        end

        should 'I want to demote and admin to member, i am not admin' do
          assert_raise CanCan::AccessDenied do
            @user.demote_admin_to_member(member: @member, orga: @my_orga)
          end
        end

        should 'I want to demote an admin to member' do
          assert_no_difference('@my_orga.roles.count') do
            @admin.demote_admin_to_member(member: @member, orga: @my_orga)
            assert_equal Role.find_by(orga: @my_orga, user: @member).title, Role::ORGA_MEMBER
          end
        end
      end
    end
  end
end
