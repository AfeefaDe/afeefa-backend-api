require 'test_helper'

class Api::V1::AnnotationCategoriesControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'I want to get all annotation categories' do
      get :index
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal AnnotationCategory.count, json['data'].size
    end

    should 'I want to get a single annotation category' do
      get :show, params: { id: AnnotationCategory.first }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Hash, json['data']
      assert_equal AnnotationCategory.first.to_hash.deep_stringify_keys, json['data']
    end
  end

end
