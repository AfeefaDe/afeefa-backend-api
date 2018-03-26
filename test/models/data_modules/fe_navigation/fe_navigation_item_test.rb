require 'test_helper'

module DataModules::FENavigation
  class FENavigationItemTest < ActiveSupport::TestCase

    should 'validate navigation item' do
      navigation_item = FENavigationItem.new
      assert_not navigation_item.valid?
      assert navigation_item.errors[:navigation_id].present?
    end

    should 'create navigation item with parent_id' do
      navigation = create(:fe_navigation_with_items)
      parent = navigation.navigation_items.first

      navigation_item = save_navigation_item(navigation_id: navigation.id, parent_id: parent.id, title: 'new navigation item')

      assert_equal navigation.id, navigation_item.navigation_id
      assert_equal parent.id, navigation_item.parent_id
      assert_equal 'new navigation item', navigation_item.title
    end

    should 'throw error on create navigation item with wrong navigation_id' do
      exception = assert_raises(ActiveRecord::RecordInvalid) {
        navigation_item = save_navigation_item(navigation_id: '', title: 'new navigation item')
      }
      assert_match 'Navigation fehlt', exception.message

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        navigation_item = save_navigation_item(navigation_id: 1, title: 'new navigation item')
      }
      assert_match 'Navigation existiert nicht.', exception.message
    end

    should 'throw error on create navigation item with wrong parent_id' do
      navigation = create(:fe_navigation_with_items_and_sub_items)
      parent = navigation.navigation_items.first
      navigation2 = create(:fe_navigation_with_items)
      parent2 = create(:fe_navigation_item, navigation: navigation2)

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        navigation_item = save_navigation_item(navigation_id: navigation.id, parent_id: 123, title: 'changed navigation item')
      }
      assert_match 'Übergeordneter Menüpunkt existiert nicht.', exception.message

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        navigation_item = save_navigation_item(navigation_id: navigation.id, parent_id: parent2.id, title: 'changed navigation item')
      }
      assert_match 'Ein übergeordneter Menüpunkt muss zur selben Navigation gehören.', exception.message

      sub_item = navigation.navigation_items.select { |item| item.parent != nil }.first

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        navigation_item = save_navigation_item(navigation_id: navigation.id, parent_id: sub_item.id, title: 'changed navigation item')
      }
      assert_match 'Ein Menüpunkt kann nicht Unterpunkt eines Unterpunktes sein.', exception.message
    end

    should 'throw error on trying to update navigation' do
      navigation = create(:fe_navigation_with_items)
      navigation2 = create(:fe_navigation_with_items)
      parent = navigation.navigation_items.first

      navigation_item = save_navigation_item(navigation_id: navigation.id, parent_id: parent.id, title: 'new navigation item')
      assert_equal navigation.id, navigation_item.navigation_id

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        navigation_item = save_navigation_item(id: navigation_item.id, navigation_id: navigation2.id)
      }
      assert_match 'Navigation kann nicht geändert werden.', exception.message

      assert_equal navigation.id, navigation_item.navigation_id
    end

    should 'throw error on update navigation item with wrong parent_id' do
      navigation = create(:fe_navigation_with_items)
      navigation2 = create(:fe_navigation_with_items)
      parent = navigation.navigation_items.first
      parent2 = create(:fe_navigation_item, navigation: navigation2)
      navigation_item = create(:fe_navigation_item, navigation: navigation)

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        navigation_item = save_navigation_item(navigation_id: navigation.id, id: navigation_item.id, parent_id: 123, title: 'changed navigation item')
      }
      assert_match 'Übergeordneter Menüpunkt existiert nicht.', exception.message

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        navigation_item = save_navigation_item(navigation_id: navigation.id, id: navigation_item.id, parent_id: parent2.id, title: 'changed navigation item')
      }
      assert_match 'Ein übergeordneter Menüpunkt muss zur selben Navigation gehören.', exception.message

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        navigation_item = save_navigation_item(navigation_id: navigation.id, id: navigation_item.id, parent_id: navigation_item.id, title: 'changed navigation item')
      }
      assert_match 'Ein Menüpunkt kann nicht sein Unterpunkt sein.', exception.message
    end

    should 'update navigation item with new parent_id' do
      navigation = create(:fe_navigation_with_items_and_sub_items)
      parent = navigation.navigation_items.select { |item| item.sub_items.count > 0 }.first
      sub_item = parent.sub_items.first
      parent2 = navigation.navigation_items.select { |item| item.sub_items.count > 0 }.last
      sub_item2_1 = parent2.sub_items.first
      sub_item2_2 = parent2.sub_items.last

      navigation_item = save_navigation_item(id: sub_item.id, parent_id: parent2.id, title: 'changed navigation item')

      assert_same_elements [sub_item2_1, sub_item2_2, sub_item], parent2.sub_items
    end

    should 'throw error on setting parent for items with sub items' do
      navigation = create(:fe_navigation_with_items_and_sub_items)
      navigation2 = create(:fe_navigation_with_items_and_sub_items)

      item_with_sub_items = navigation.navigation_items.select { |item| item.sub_items.count > 0 }.first
      new_parent = navigation2.navigation_items.first

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        navigation_item = save_navigation_item(id: item_with_sub_items.id, parent_id: new_parent.id, title: 'changed navigation item')
      }
      assert_match 'Ein Menüpunkt mit Unterpunkten kann nicht verschachtelt werden.', exception.message
    end

    should 'throw error on setting parent to a sub item' do
      navigation = create(:fe_navigation_with_items_and_sub_items)
      parent = navigation.navigation_items.select { |item| item.sub_items.count > 0 }.first
      sub_item = parent.sub_items.first
      parent2 = navigation.navigation_items.select { |item| item.sub_items.count > 0 }.last
      sub_item2 = parent2.sub_items.first

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        navigation_item = save_navigation_item(id: sub_item.id, parent_id: sub_item2.id, title: 'changed navigation item')
      }
      assert_match 'Ein Menüpunkt kann nicht Unterpunkt eines Unterpunktes sein.', exception.message
    end

    should 'remove all sub items on remove navigation item' do
      navigation = create(:fe_navigation_with_items_and_sub_items)
      parent = navigation.navigation_items.select { |item| item.sub_items.count > 0 }.first
      sub_item = parent.sub_items.first

      assert_difference -> { FENavigationItem.count }, -3 do # parent + 2 subs
        parent.destroy
      end

      assert FENavigationItem.where(id: parent.id).blank?
      assert FENavigationItem.where(id: sub_item.id).blank?
    end

    should 'link and get owners of mixed types' do
      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first

      orga = create(:orga)
      event = create(:event)
      offer = create(:offer)

      assert_difference -> { FENavigationItemOwner.count }, 3 do
        navigation_item.link_owner(orga)
        navigation_item.link_owner(event)
        navigation_item.link_owner(offer)
      end

      assert_same_elements [orga, event, offer], navigation_item.owners
    end

    should 'relink owners with new/old parent when setting a new parent' do
      navigation = create(:fe_navigation_with_items_and_sub_items)

      parent = navigation.navigation_items.select { |item| item.parent == nil }.first
      parent2 = navigation.navigation_items.select { |item| item.parent == nil }.last

      sub_item = parent.sub_items.first

      orgas = create_list(:orga_with_random_title, 3)
      parent.orgas = orgas
      sub_item.orgas = orgas

      assert_equal orgas, parent.orgas
      assert_equal [], parent2.orgas

      save_navigation_item(id: sub_item.id, parent_id: parent2.id)

      parent.reload
      parent2.reload
      sub_item.reload

      assert_equal [], parent.orgas
      assert_equal orgas, parent2.orgas
      assert_equal orgas, sub_item.orgas
    end

    should 'keep other owners when relinking on setting a new parent' do
      navigation = create(:fe_navigation_with_items_and_sub_items)

      parent = navigation.navigation_items.select { |item| item.parent == nil }.first
      parent2 = navigation.navigation_items.select { |item| item.parent == nil }.last

      sub_item = parent.sub_items.first
      sub_item2 = parent.sub_items.last

      orgas = create_list(:orga_with_random_title, 1)
      parent.orgas = orgas
      sub_item.orgas = orgas
      sub_item2.orgas = orgas

      assert_equal orgas, parent.orgas
      assert_equal orgas, sub_item.orgas
      assert_equal orgas, sub_item2.orgas
      assert_equal [], parent2.orgas

      save_navigation_item(id: sub_item.id, parent_id: parent2.id)

      parent.reload
      parent2.reload
      sub_item.reload
      sub_item2.reload

      assert_equal orgas, parent.orgas
      assert_equal orgas, sub_item.orgas
      assert_equal orgas, sub_item2.orgas
      assert_equal orgas, parent2.orgas
    end

    should 'also link parent navigation item if linking a sub item' do
      navigation = create(:fe_navigation_with_items_and_sub_items)

      parent = navigation.navigation_items.select { |item| item.parent == nil }.first
      sub_item = parent.sub_items.first

      orga = create(:orga)

      assert_difference -> { FENavigationItemOwner.count }, 2 do
        sub_item.link_owner(orga)

        assert_equal [orga], parent.owners
        assert_equal [orga], sub_item.owners
      end
    end

    should 'not link parent twice when linking a sub item' do
      navigation = create(:fe_navigation_with_items_and_sub_items)

      parent = navigation.navigation_items.select { |item| item.parent == nil }.first
      sub_item = parent.sub_items.first

      orga = create(:orga)
      parent.link_owner(orga)

      sub_item.link_owner(orga)

      assert_equal [orga], parent.owners
      assert_equal [orga], sub_item.owners
    end

    should 'should also unlink sub items if unlinking parent item' do
      navigation = create(:fe_navigation_with_items_and_sub_items)

      parent = navigation.navigation_items.select { |item| item.parent == nil }.first
      sub_item = parent.sub_items.first

      orga = create(:orga)
      parent.link_owner(orga)
      sub_item.link_owner(orga)

      assert_equal [orga], parent.owners
      assert_equal [orga], sub_item.owners

      assert_difference -> { FENavigationItemOwner.count }, -2 do
        parent.unlink_owner(orga)

        parent.reload
        sub_item.reload

        assert_equal [], parent.owners
        assert_equal [], sub_item.owners
      end
    end

    should 'remove owners when removing navigation item' do
      navigation = create(:fe_navigation_with_items_and_sub_items)

      parent = navigation.navigation_items.select { |item| item.parent == nil }.first
      sub_item = parent.sub_items.first

      orga = create(:orga)
      parent.link_owner(orga)
      sub_item.link_owner(orga)

      assert_equal [orga], parent.owners
      assert_equal [orga], sub_item.owners

      assert_difference -> { FENavigationItemOwner.count }, -2 do
        parent.destroy
      end
    end

    private

    def save_navigation_item(hash)
      FENavigationItem.save_navigation_item(ActionController::Parameters.new(hash))
    end

  end
end
