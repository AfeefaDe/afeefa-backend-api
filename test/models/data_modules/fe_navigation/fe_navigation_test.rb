require 'test_helper'

module DataModules::FeNavigation
  class FeNavigationTest < ActiveSupport::TestCase
    test 'validate navigation' do
      navigation = DataModules::FeNavigation::FeNavigation.new
      assert navigation.valid?
    end

    test 'create navigation with items' do
      navigation = create(:fe_navigation)
      assert_equal [], navigation.navigation_items

      navigation2 = create(:fe_navigation_with_items)
      assert_equal 2, navigation2.navigation_items.count

      navigation3 = create(:fe_navigation_with_items_and_sub_items)
      assert_equal 6, navigation3.navigation_items.count

      navigation3.navigation_items.each do |item|
        if item.parent == nil
          assert_equal 2, item.sub_items.count
        else
          assert_equal 0, item.sub_items.count
        end
      end
    end

    test 'remove all navigation items on delete' do
      navigation = create(:fe_navigation)
      assert_no_difference -> { FeNavigationItem.count } do
        navigation.destroy
      end

      navigation2 = create(:fe_navigation_with_items)
      assert_difference -> { FeNavigationItem.count }, -2 do
        navigation2.destroy
      end

      navigation3 = create(:fe_navigation_with_items_and_sub_items)
      assert_difference -> { FeNavigationItem.count }, -6 do
        navigation3.destroy
      end
    end

    test 'should order navigation items' do
      item_count = 5
      sub_item_count = 5
      navigation =
        create(:fe_navigation_with_items_and_sub_items, items_count: item_count, sub_items_count: sub_item_count)
      assert_equal item_count + item_count * sub_item_count, navigation.navigation_items.count

      ids_shuffled = navigation.navigation_items.pluck(:id).shuffle
      ids_not_to_order = ids_shuffled[0..9]
      assert ids_not_to_order.any?
      ids_to_order = ids_shuffled - ids_not_to_order
      assert ids_to_order.any?

      navigation.order_navigation_items!(ids_to_order)

      assert_equal [0], FeNavigationItem.where(id: ids_not_to_order).pluck(:order).uniq
      assert_equal ids_to_order, navigation.navigation_items.ordered.pluck(:id) - ids_not_to_order
    end
  end
end
