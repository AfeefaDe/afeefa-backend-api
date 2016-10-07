require 'test_helper'

class Orga::Operations::ListUsersTest < ActiveSupport::TestCase

  context 'As admin' do
    setup do
      @admin = admin
      @member = member
    end

    should 'I want a list of all users in my orgas' do
      op = Orga::Operations::ListUsers.present({current_user: @admin,
                                    id: @admin.orgas.first.id})
      assert_equal @admin.orgas.first.users, op.model
    end

    should 'I want a list of all users in a different orgas' do
      assert_raise CanCan::AccessDenied do
        Orga::Operations::ListUsers.present({current_user: @admin,
                                 id: @member.orgas.last.id})
      end
    end
  end
end