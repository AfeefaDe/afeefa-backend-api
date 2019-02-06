require 'test_helper'

class DataModules::FeNavigation::V1::FeNavigationControllerTest < ActionController::TestCase
    
  setup do
    stub_current_user
  end

  test 'get items' do
    create(:fe_navigation_with_items_and_sub_items)

    get :show

    assert_response :ok

    json = JSON.parse(response.body)
    assert_kind_of Hash, json

    json_items = json['relationships']['navigation_items']['data']
    assert_kind_of Array, json_items
    assert_equal 2, json_items.count
    order_attributes = json_items.map { |element| element['attributes']['order'] }
    assert_equal order_attributes.sort, order_attributes

    json_sub_items = json_items[0]['relationships']['sub_items']['data']
    assert_kind_of Array, json_sub_items
    assert_equal 2, json_sub_items.count
    order_attributes = json_sub_items.map { |element| element['attributes']['order'] }
    assert_equal order_attributes.sort, order_attributes
  end

  test 'not change order of navigation items for empty list of ids' do
    navigation = create(:fe_navigation_with_items_and_sub_items, items_count: 3, sub_items_count: 3)
    assert_not_equal [0], navigation.navigation_items.pluck(:order).uniq

    patch :set_ordered_navigation_items, params: { navigation_item_ids: [] }
    assert_response :no_content

    assert_not_equal [0], navigation.navigation_items.pluck(:order).uniq
  end

  test 'change order of navigation items' do
    navigation = create(:fe_navigation_with_items_and_sub_items, items_count: 3, sub_items_count: 3)
    assert_not_equal [0], navigation.navigation_items.pluck(:order).uniq

    ids_shuffled = navigation.navigation_items.pluck(:id).shuffle
    ids_not_to_order = ids_shuffled[0..9]
    assert ids_not_to_order.any?
    ids_to_order = ids_shuffled - ids_not_to_order
    assert ids_to_order.any?

    patch :set_ordered_navigation_items, params: { navigation_item_ids: ids_to_order }
    assert_response :ok

    assert_not_equal [0], navigation.navigation_items.where(id: ids_to_order).pluck(:order).uniq
    assert_equal [0], navigation.navigation_items.where.not(id: ids_to_order).pluck(:order).uniq
  end

end
