require 'test_helper'

class Api::V1::CategoriesControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'I want to get all categories' do
      get :index
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Category.count, json['data'].size
    end
  end

end
