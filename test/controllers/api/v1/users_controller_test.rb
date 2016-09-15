require 'test_helper'

class Api::V1::UsersControllerTest < ActionController::TestCase

  context 'As user' do
    setup do
      @user = User.first
      stub_current_user(user: @user)
    end

    should 'I want to show my user' do
      get :show, params: { id: @user.id }
      assert_response :success
      expected = ActiveModelSerializers::SerializableResource.new(@user, {}).to_json
      assert_equal expected, response.body
    end

  end
end
