require 'test_helper'

module DataModules::FENavigation
  class FENavigationItemTest < ActiveSupport::TestCase

    include ActsAsFacetItemTest

    # ActsAsFacetItemTest

    def create_root
      create(:fe_navigation)
    end

    def create_root_with_items
      create(:fe_navigation_with_items)
    end

    def create_root_with_items_and_sub_items
      create(:fe_navigation_with_items_and_sub_items)
    end

    def create_item
      create(:fe_navigation_item)
    end

    def create_item_with_root(navigation)
      create(:fe_navigation_item, navigation: navigation)
    end

    def get_root_items(navigation)
      navigation.navigation_items
    end

    def root_id_field
      'navigation_id'
    end

    def ownerClass
      DataModules::FENavigation::FENavigationItemOwner
    end

    def itemClass
      DataModules::FENavigation::FENavigationItem
    end

    def save_item(hash)
      FENavigationItem.save_navigation_item(ActionController::Parameters.new(hash))
    end

    def message_root_missing
      'Navigation fehlt'
    end

    def message_root_nonexisting
      'Navigation existiert nicht.'
    end

    def message_parent_nonexisting
      'Übergeordneter Menüpunkt existiert nicht.'
    end

    def message_parent_wrong_root
      'Ein übergeordneter Menüpunkt muss zur selben Navigation gehören.'
    end

    def message_item_sub_of_sub
      'Ein Menüpunkt kann nicht Unterpunkt eines Unterpunktes sein.'
    end

    def message_sub_of_itself
      'Ein Menüpunkt kann nicht sein Unterpunkt sein.'
    end

    def message_sub_cannot_be_nested
      'Ein Menüpunkt mit Unterpunkten kann nicht verschachtelt werden.'
    end

    # FENavigationItemTest

    should 'throw error on trying to update navigation' do
      navigation = create(:fe_navigation_with_items)
      navigation2 = create(:fe_navigation_with_items)
      parent = navigation.navigation_items.first

      navigation_item = save_item(navigation_id: navigation.id, parent_id: parent.id, title: 'new navigation item')
      assert_equal navigation.id, navigation_item.navigation_id

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        navigation_item = save_item(id: navigation_item.id, navigation_id: navigation2.id)
      }
      assert_match 'Navigation kann nicht geändert werden.', exception.message

      assert_equal navigation.id, navigation_item.navigation_id
    end

    should 'disallow linking facet' do
      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first

      facet = create(:facet_with_items)

      assert !navigation_item.link_owner(facet)
      assert_equal [], navigation_item.owners
    end

    should 'link facet item' do
      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first

      facet = create(:facet_with_items, owner_types: ['Orga'])
      facet_item = facet.facet_items.first
      orga = create(:orga)
      facet_item.link_owner(orga)

      assert navigation_item.link_owner(facet_item)
      assert_equal [orga], navigation_item.owners
      assert_equal [facet_item], navigation_item.facet_items
    end

    should 'unlink facet item' do
      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first

      facet = create(:facet_with_items, owner_types: ['Orga'])
      facet_item = facet.facet_items.first
      orga = create(:orga)
      facet_item.link_owner(orga)

      assert navigation_item.link_owner(facet_item)
      assert_equal [orga], navigation_item.owners
      assert_equal [facet_item], navigation_item.facet_items

      assert navigation_item.unlink_owner(facet_item)
      navigation_item.reload

      assert_equal [], navigation_item.owners
      assert_equal [], navigation_item.facet_items
    end

    should 'not duplicate owners when linked directly and linked through facet_item' do
      orga = create(:orga)

      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first
      navigation_item.link_owner(orga)

      facet = create(:facet_with_items, owner_types: ['Orga'])
      facet_item = facet.facet_items.first
      facet_item.link_owner(orga)

      assert navigation_item.link_owner(facet_item)
      assert_equal [orga], navigation_item.owners
      assert_equal [facet_item], navigation_item.facet_items
    end

  end
end
