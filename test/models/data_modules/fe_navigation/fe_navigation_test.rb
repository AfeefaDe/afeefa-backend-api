require 'test_helper'

module DataModules::FENavigation
  class FENavigationTest < ActiveSupport::TestCase

    should 'validate navigation' do
      navigation = DataModules::FENavigation::FENavigation.new
      assert navigation.valid?
    end

    should 'create navigation with items' do
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

    should 'remove all navigation items on delete' do
      navigation = create(:fe_navigation)
      assert_no_difference -> { FENavigationItem.count } do
        navigation.destroy
      end

      navigation2 = create(:fe_navigation_with_items)
      assert_difference -> { FENavigationItem.count }, -2 do
        navigation2.destroy
      end

      navigation3 = create(:fe_navigation_with_items_and_sub_items)
      assert_difference -> { FENavigationItem.count }, -6 do
        navigation3.destroy
      end
    end

  end
end
