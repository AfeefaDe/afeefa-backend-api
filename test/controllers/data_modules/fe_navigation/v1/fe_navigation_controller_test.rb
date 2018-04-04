require 'test_helper'

class DataModules::FeNavigation::V1::FeNavigationControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get items' do
      navigation = create(:fe_navigation_with_items_and_sub_items)

      get :show

      assert_response :ok

      json = JSON.parse(response.body)
      assert_kind_of Hash, json

      json_items = json['relationships']['navigation_items']['data']
      assert_kind_of Array, json_items
      assert_equal 2, json_items.count

      json_sub_items = json_items[0]['relationships']['sub_items']['data']
      assert_kind_of Array, json_sub_items
      assert_equal 2, json_sub_items.count
    end

  end
end
