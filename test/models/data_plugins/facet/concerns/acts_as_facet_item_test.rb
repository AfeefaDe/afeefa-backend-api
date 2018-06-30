module ActsAsFacetItemTest
  extend ActiveSupport::Concern

  included do

    should 'validate facet' do
      item = itemClass.new
      assert_not item.valid?
      assert item.errors[root_id_field].present?
    end

    should 'create item triggers fapi cache' do
      FapiClient.any_instance.expects(:entry_updated).with(instance_of(itemClass)).at_least_once

      create_item
    end

    should 'update item triggers fapi cache' do
      item = create_item

      FapiClient.any_instance.expects(:entry_updated).with(item)

      item.update(title: 'new title')
    end

    should 'remove item triggers fapi cache' do
      item = create_item

      FapiClient.any_instance.expects(:entry_deleted).with(item)

      item.destroy
    end

    should 'create item with parent_id' do
      root = create_root_with_items
      parent = get_root_items(root).first

      item = save_item(root_id_field => root.id, parent_id: parent.id, title: 'new item')

      assert_equal root.id, item[root_id_field]
      assert_equal parent.id, item.parent_id
      assert_equal 'new item', item.title
    end

    should 'throw error on create item with wrong root id' do
      exception = assert_raises(ActiveRecord::RecordInvalid) {
        item = save_item(root_id_field => '', title: 'new item')
      }
      assert_match message_root_missing, exception.message

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        item = save_item(root_id_field => 1, title: 'new item')
      }
      assert_match message_root_nonexisting, exception.message
    end

    should 'throw error on create item with wrong parent_id' do
      root = create_root_with_items_and_sub_items
      parent = get_root_items(root).first
      root2 = create_root_with_items_and_sub_items
      parent2 = create_item_with_root(root2)

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        item = save_item(root_id_field => root.id, parent_id: 123, title: 'changed item')
      }
      assert_match message_parent_nonexisting, exception.message

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        item = save_item(root_id_field => root.id, parent_id: parent2.id, title: 'changed item')
      }
      assert_match message_parent_wrong_root, exception.message

      sub_item = get_root_items(root).select { |item| item.parent != nil }.first

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        item = save_item(root_id_field => root.id, parent_id: sub_item.id, title: 'changed item')
      }
      assert_match message_item_sub_of_sub, exception.message

      item_with_sub_items = get_root_items(root).select { |item| item.sub_items.count > 0 }.first
      new_parent = get_root_items(root2).first

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        item = save_item(id: item_with_sub_items.id, parent_id: new_parent.id, title: 'changed item')
      }
      assert_match message_sub_cannot_be_nested, exception.message
    end

    should 'update item with new parent_id' do
      root = create_root_with_items_and_sub_items
      parent = get_root_items(root).select { |item| item.sub_items.count > 0 }.first
      sub_item = parent.sub_items.first
      sub_item2 = parent.sub_items.last
      parent2 = get_root_items(root).select { |item| item.sub_items.count > 0 }.last
      sub_item2_1 = parent2.sub_items.first
      sub_item2_2 = parent2.sub_items.last

      item = save_item(id: sub_item.id, parent_id: parent2.id, title: 'changed item')

      assert_same_elements [sub_item2], parent.sub_items
      assert_same_elements [sub_item2_1, sub_item2_2, sub_item], parent2.sub_items
    end

    should 'throw error on update item with wrong parent_id' do
      root = create_root_with_items_and_sub_items
      root2 = create_root_with_items
      parent = get_root_items(root).first
      parent2 = create_item_with_root(root2)
      item = create_item_with_root(root)

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        item = save_item(root_id_field => root.id, id: item.id, parent_id: 123, title: 'changed item')
      }
      assert_match message_parent_nonexisting, exception.message

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        item = save_item(root_id_field => root.id, id: item.id, parent_id: parent2.id, title: 'changed item')
      }
      assert_match message_parent_wrong_root, exception.message

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        item = save_item(root_id_field => root.id, id: item.id, parent_id: item.id, title: 'changed item')
      }
      assert_match message_sub_of_itself, exception.message

      sub_item = get_root_items(root).select { |item| item.parent != nil }.first

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        item = save_item(root_id_field => root.id, id: item.id, parent_id: sub_item.id, title: 'changed item')
      }
      assert_match message_item_sub_of_sub, exception.message

      item_with_sub_items = get_root_items(root).select { |item| item.sub_items.count > 0 }.first
      new_parent = get_root_items(root2).first

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        item = save_item(id: item_with_sub_items.id, parent_id: new_parent.id, title: 'changed item')
      }
      assert_match message_sub_cannot_be_nested, exception.message
    end

    should 'remove all sub items on remove item' do
      root = create_root_with_items_and_sub_items
      parent = get_root_items(root).select { |item| item.sub_items.count > 0 }.first
      sub_item = parent.sub_items.first

      assert_difference -> { itemClass.count }, -3 do # parent + 2 subs
        parent.destroy
      end

      assert itemClass.where(id: parent.id).blank?
      assert itemClass.where(id: sub_item.id).blank?
    end

    should 'link and get owners of mixed types' do
      root = create_root_with_items
      item = get_root_items(root).first

      orga = create(:orga)
      event = create(:event)
      offer = create(:offer)

      assert_difference -> { ownerClass.count }, 3 do
        item.link_owner(orga)
        item.link_owner(event)
        item.link_owner(offer)
      end

      assert_same_elements [orga, event, offer], item.owners
    end


    should 'relink owners with new/old parent when setting a new parent' do
      root = create_root_with_items_and_sub_items

      parent = get_root_items(root).select { |item| item.parent == nil }.first
      parent2 = get_root_items(root).select { |item| item.parent == nil }.last

      sub_item = parent.sub_items.first

      orga1 = create(:orga_with_random_title)
      orgas = create_list(:orga_with_random_title, 3)
      parent.orgas = orgas + [orga1]
      sub_item.orgas = orgas

      assert_equal orgas + [orga1], parent.owners
      assert_equal orgas, sub_item.owners
      assert_equal [], parent2.owners

      save_item(id: sub_item.id, parent_id: parent2.id)

      parent.reload
      parent2.reload
      sub_item.reload

      assert_equal [orga1], parent.owners
      assert_equal orgas, parent2.owners
      assert_equal orgas, sub_item.owners
    end

    should 'keep other owners when relinking on setting a new parent' do
      root = create_root_with_items_and_sub_items

      parent = get_root_items(root).select { |item| item.parent == nil }.first
      parent2 = get_root_items(root).select { |item| item.parent == nil }.last

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

      save_item(id: sub_item.id, parent_id: parent2.id)

      parent.reload
      parent2.reload
      sub_item.reload
      sub_item2.reload

      assert_equal orgas, parent.orgas
      assert_equal orgas, sub_item.orgas
      assert_equal orgas, sub_item2.orgas
      assert_equal orgas, parent2.orgas
    end

    should 'also link parent item if linking a sub item' do
      root = create_root_with_items_and_sub_items

      parent = get_root_items(root).select { |item| item.parent == nil }.first
      sub_item = parent.sub_items.first

      orga = create(:orga)

      assert_difference -> { ownerClass.count }, 2 do
        sub_item.link_owner(orga)

        assert_equal [orga], parent.owners
        assert_equal [orga], sub_item.owners
      end
    end

    should 'not link parent twice when linking a sub item' do
      root = create_root_with_items_and_sub_items

      parent = get_root_items(root).select { |item| item.parent == nil }.first
      sub_item = parent.sub_items.first

      orga = create(:orga)
      parent.link_owner(orga)

      sub_item.link_owner(orga)

      assert_equal [orga], parent.owners
      assert_equal [orga], sub_item.owners
    end

    should 'should also unlink sub items if unlinking parent item' do
      root = create_root_with_items_and_sub_items

      parent = get_root_items(root).select { |item| item.parent == nil }.first
      sub_item = parent.sub_items.first

      orga = create(:orga)
      parent.link_owner(orga)
      sub_item.link_owner(orga)

      assert_equal [orga], parent.owners
      assert_equal [orga], sub_item.owners

      assert_difference -> { ownerClass.count }, -2 do
        parent.unlink_owner(orga)

        parent.reload
        sub_item.reload

        assert_equal [], parent.owners
        assert_equal [], sub_item.owners
      end
    end

    should 'remove owners when removing parent item' do
      root = create_root_with_items_and_sub_items

      parent = get_root_items(root).select { |item| item.parent == nil }.first
      sub_item = parent.sub_items.first

      orga = create(:orga)
      parent.link_owner(orga)
      sub_item.link_owner(orga)

      assert_equal [orga], parent.owners
      assert_equal [orga], sub_item.owners

      assert_difference -> { ownerClass.count }, -2 do
        parent.destroy
      end
    end

    should 'remove owners when removing sub item' do
      root = create_root_with_items_and_sub_items

      parent = get_root_items(root).select { |item| item.parent == nil }.first
      sub_item = parent.sub_items.first

      orga = create(:orga)
      parent.link_owner(orga)
      sub_item.link_owner(orga)

      assert_equal [orga], parent.owners
      assert_equal [orga], sub_item.owners

      assert_difference -> { ownerClass.count }, -1 do
        sub_item.destroy

        assert_equal [orga], parent.owners
      end
    end

  end

end
