require 'test_helper'

class User::Operations::ListEventsTest < ActiveSupport::TestCase

  context 'As admin' do
    setup do
      @admin = admin
      @member = member
    end

    should 'I want a list of all my orgas' do
      op = User::Operations::ListEvents.present({current_user: @admin,
                                     id: @admin.id})
      assert_equal @admin.events, op.model
    end

    should 'I want a list of all events of a different user' do
      assert_raise CanCan::AccessDenied do
        User::Operations::ListEvents.present({current_user: @admin,
                                  id: @member.id})
      end
    end
  end
end