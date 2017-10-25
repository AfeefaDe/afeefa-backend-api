require 'test_helper'

class Api::V1::ResourceItemsControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'I want to get all resources' do
      get :index
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal ResourceItem.count, json['data'].size
    end

    should 'I want to get a single resource' do
      orga = create(:orga, title: 'foobar')
      resource = create(:resource_item, orga: orga)

      get :show, params: { id: resource.id }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Hash, json['data']
      assert_equal ResourceItem.last.to_hash.deep_stringify_keys, json['data']
      assert_equal resource.title, json['data']['attributes']['title']
      assert_equal resource.description, json['data']['attributes']['description']
      assert_equal resource.tags, json['data']['attributes']['tags']
      # assert_equal resource.url, json['data']['attributes']['url']
    end
  end

end
