require 'test_helper'

class Api::V1::TodosControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user(user: User.first)
    end

    should 'get index' do
      get :index
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 1, json['data'].size
    end

  end

end
