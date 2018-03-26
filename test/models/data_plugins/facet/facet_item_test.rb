require 'test_helper'

module DataPlugins::Facet
  class FacetItemTest < ActiveSupport::TestCase

    should 'validate facet' do
      facet_item = FacetItem.new
      assert_not facet_item.valid?
      assert facet_item.errors[:facet_id].present?
    end

    should 'create facet item with parent_id' do
      facet = create(:facet)
      parent = create(:facet_item, facet: facet)

      facet_item = save_facet_item(facet_id: facet.id, parent_id: parent.id, title: 'new facet item')

      assert_equal facet.id, facet_item.facet_id
      assert_equal parent.id, facet_item.parent_id
      assert_equal 'new facet item', facet_item.title
    end

    should 'throw error on create facet item with wrong facet_id' do
      exception = assert_raises(ActiveRecord::RecordInvalid) {
        facet_item = save_facet_item(facet_id: '', title: 'new facet item')
      }
      assert_match 'Facet fehlt', exception.message

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        facet_item = save_facet_item(facet_id: 1, title: 'new facet item')
      }
      assert_match 'Kategorie existiert nicht.', exception.message
    end

    should 'throw error on create facet item with wrong parent_id' do
      facet = create(:facet)
      parent = create(:facet_item)

      # parent_id does not exist
      exception = assert_raises(ActiveRecord::RecordInvalid) {
        facet_item = save_facet_item(facet_id: facet.id, parent_id: 123, title: 'new facet item')
      }
      assert_match 'Übergeordnetes Attribut existiert nicht.', exception.message

      # parent_id does not belong to facet
      exception = assert_raises(ActiveRecord::RecordInvalid) {
        facet_item = save_facet_item(facet_id: facet.id, parent_id: parent.id, title: 'new facet item')
      }
      assert_match 'Ein übergeordnetes Attribut muss zur selben Kategorie gehören.', exception.message
    end

    should 'update facet item with new parent' do
      facet = create(:facet)
      facet2 = create(:facet)
      parent = create(:facet_item, facet: facet)
      parent2 = create(:facet_item, facet: facet2)
      facet_item = create(:facet_item, facet: facet)

      facet_item = save_facet_item(id: facet_item.id, parent_id: parent.id, title: 'changed facet item')
      assert_equal facet_item.facet_id, facet.id
      assert_equal facet_item.parent_id, parent.id

      facet_item = save_facet_item(facet_id: facet2.id, id: facet_item.id, parent_id: parent2.id, title: 'changed facet item')
      assert_equal facet_item.facet_id, facet2.id
      assert_equal facet_item.parent_id, parent2.id
    end

    should 'throw error on update facet item with wrong facet_id' do
      facet = create(:facet)
      facet_item = create(:facet_item, facet: facet)

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        facet_item = save_facet_item(facet_id: '', id: facet_item.id, title: 'changed facet item')
      }
      assert_match 'Facet fehlt', exception.message

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        facet_item = save_facet_item(facet_id: 123, id: facet_item.id, title: 'changed facet item')
      }
      assert_match 'Kategorie existiert nicht.', exception.message

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        facet_item = save_facet_item(facet_id: nil, id: facet_item.id, title: 'changed facet item')
      }
      assert_match 'Facet fehlt', exception.message
    end

    should 'throw error on update facet item with wrong parent_id' do
      facet = create(:facet)
      facet2 = create(:facet)
      parent2 = create(:facet_item, facet: facet2)
      facet_item = create(:facet_item, facet: facet)

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        facet_item = save_facet_item(facet_id: facet.id, id: facet_item.id, parent_id: 123, title: 'changed facet item')
      }
      assert_match 'Übergeordnetes Attribut existiert nicht.', exception.message

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        facet_item = save_facet_item(facet_id: facet.id, id: facet_item.id, parent_id: parent2.id, title: 'changed facet item')
      }
      assert_match 'Ein übergeordnetes Attribut muss zur selben Kategorie gehören.', exception.message
    end

    should 'throw error on setting parent for items with sub items' do
      facet = create(:facet_with_items_and_sub_items)
      facet2 = create(:facet_with_items_and_sub_items)

      item_with_sub_items = facet.facet_items.select { |item| item.sub_items.count > 0 }.first
      new_parent = facet2.facet_items.first

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        facet_item = save_facet_item(id: item_with_sub_items.id, parent_id: new_parent.id, title: 'changed facet item')
      }
      assert_match 'Ein Attribut mit Unterattributen kann nicht verschachtelt werden.', exception.message
    end

    should 'throw error on setting parent to a sub item' do
      facet = create(:facet_with_items)
      facet2 = create(:facet_with_items_and_sub_items)

      item = facet.facet_items.first
      sub_item = facet2.facet_items.select { |item| item.parent != nil }.first

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        facet_item = save_facet_item(facet_id: facet2.id, id: item.id, parent_id: sub_item.id, title: 'changed facet item')
      }
      assert_match 'Ein Attribut kann nicht Unterattribut eines Unterattributs sein.', exception.message
    end

    should 'updates sub_items facet on update facet item facet ' do
      facet = create(:facet)
      facet2 = create(:facet)
      sub_item = create(:facet_item, facet: facet)
      facet_item = create(:facet_item, facet: facet)
      facet_item.sub_items << sub_item

      save_facet_item(facet_id: facet2.id, id: facet_item.id)

      facet_item.reload
      sub_item.reload

      assert_equal facet2.id, facet_item.facet_id
      assert_equal facet2.id, sub_item.facet_id

    end

    should 'remove all sub items on remove facet item' do
      facet = create(:facet)
      sub_item = create(:facet_item, facet: facet)
      facet_item = create(:facet_item, facet: facet)
      facet_item.sub_items << sub_item

      facet_item.destroy()

      assert DataPlugins::Facet::FacetItem.where(id: facet_item.id).blank?
      assert DataPlugins::Facet::FacetItem.where(id: sub_item.id).blank?
    end

    should 'relink owners with new/old parent when setting a new parent' do
      facet = create(:facet_with_items_and_sub_items)

      parent = facet.facet_items.select { |item| item.parent == nil }.first
      parent2 = facet.facet_items.select { |item| item.parent == nil }.last

      sub_item = parent.sub_items.first

      orgas = create_list(:orga_with_random_title, 3)
      parent.orgas = orgas
      sub_item.orgas = orgas

      assert_equal orgas, parent.orgas
      assert_equal [], parent2.orgas

      save_facet_item(id: sub_item.id, parent_id: parent2.id)

      parent.reload
      parent2.reload
      sub_item.reload

      assert_equal [], parent.orgas
      assert_equal orgas, parent2.orgas
      assert_equal orgas, sub_item.orgas
    end

    should 'should also link parent facet item if linking a sub item' do
      facet = create(:facet_with_items_and_sub_items, owner_types: ['Orga'])

      parent = facet.facet_items.select { |item| item.parent == nil }.first
      sub_item = parent.sub_items.first

      orga = create(:orga)

      assert_difference -> { DataPlugins::Facet::OwnerFacetItem.count }, 2 do
        sub_item.link_owner(orga)
        assert_equal [parent, sub_item], orga.facet_items
      end
    end

    should 'not link parent twice when linking a sub item' do
      facet = create(:facet_with_items_and_sub_items, owner_types: ['Orga'])

      parent = facet.facet_items.select { |item| item.parent == nil }.first
      sub_item = parent.sub_items.first

      orga = create(:orga)
      parent.link_owner(orga)

      sub_item.link_owner(orga)

      assert_equal [parent, sub_item], orga.facet_items
    end

    should 'should also unlink sub items if unlinking parent item' do
      facet = create(:facet_with_items_and_sub_items, owner_types: ['Orga'])

      parent = facet.facet_items.select { |item| item.parent == nil }.first
      sub_item = parent.sub_items.first

      orga = create(:orga)
      parent.link_owner(orga)
      sub_item.link_owner(orga)

      assert_equal [parent, sub_item], orga.facet_items

      assert_difference -> { DataPlugins::Facet::OwnerFacetItem.count }, -2 do
        parent.unlink_owner(orga)

        assert_equal [], orga.facet_items
      end
    end

    should 'remove owners when removing facet item' do
      facet = create(:facet_with_items_and_sub_items, owner_types: ['Orga'])

      parent = facet.facet_items.select { |item| item.parent == nil }.first
      sub_item = parent.sub_items.first

      orga = create(:orga)
      parent.link_owner(orga)
      sub_item.link_owner(orga)

      assert_equal [parent, sub_item], orga.facet_items

      assert_difference -> { DataPlugins::Facet::OwnerFacetItem.count }, -2 do
        parent.destroy

        orga.reload

        assert_equal [], orga.facet_items
      end
    end

    should 'remove sub items when removing facet item' do
      facet = create(:facet_with_items_and_sub_items, owner_types: ['Orga'])
      parent = facet.facet_items.select { |item| item.parent == nil }.first

      assert_difference -> { DataPlugins::Facet::FacetItem.count }, -3 do # parent + 2 subs
        parent.destroy
      end
    end

    private

    def save_facet_item(hash)
      DataPlugins::Facet::FacetItem.save_facet_item(ActionController::Parameters.new(hash))
    end

  end
end
