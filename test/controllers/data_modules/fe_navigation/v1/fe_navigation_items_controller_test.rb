require 'test_helper'

class DataModules::FENavigation::V1::FENavigationItemsControllerTest < ActionController::TestCase

  include ActsAsFacetItemControllerTest

  def create_root
    create(:fe_navigation)
  end

  def create_root_with_items
    create(:fe_navigation_with_items)
  end

  def create_root_with_items_and_sub_items
    create(:fe_navigation_with_items_and_sub_items)
  end

  def create_item_with_root(navigation)
    create(:fe_navigation_item, navigation: navigation)
  end

  def get_root_items(navigation)
    navigation.navigation_items
  end

  def get_owner_items(owner)
    owner.navigation_items
  end

  def ownerClass
    DataModules::FENavigation::FENavigationItemOwner
  end

  def itemClass
    DataModules::FENavigation::FENavigationItem
  end

  def params(root, params)
    params
  end

end
