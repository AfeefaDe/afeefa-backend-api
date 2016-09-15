require 'test_helper'

class User::Operations::ShowTest < ActiveSupport::TestCase

  context 'As user' do
    setup do
      @user = valid_user
    end

    should 'I want the details of one specific user' do
      op = User::Operations::Show.present({id: @user.id})

      assert_equal @user.forename, op.model.forename
      assert_equal @user.surname, op.model.surname
    end
  end
end