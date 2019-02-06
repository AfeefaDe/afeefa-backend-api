require 'test_helper'

module DataPlugins::Facet
  class FacetItemTest < ActiveSupport::TestCase

    include ActsAsFacetItemTest

    # ActsAsFacetItemTest

    def create_root
      create(:facet, owner_types: ['Orga', 'Event', 'Offer'])
    end

    def create_root_with_items
      create(:facet_with_items, owner_types: ['Orga', 'Event', 'Offer'])
    end

    def create_root_with_items_and_sub_items
      create(:facet_with_items_and_sub_items, owner_types: ['Orga', 'Event', 'Offer'])
    end

    def create_item
      create(:facet_item)
    end

    def create_item_with_root(facet)
      create(:facet_item, facet: facet)
    end

    def get_root_items(facet)
      facet.facet_items
    end

    def root_id_field
      'facet_id'
    end

    def ownerClass
      DataPlugins::Facet::FacetItemOwner
    end

    def itemClass
      DataPlugins::Facet::FacetItem
    end

    def save_item(hash)
      FacetItem.save_facet_item(ActionController::Parameters.new(hash))
    end

    def message_root_missing
      'Facet fehlt'
    end

    def message_root_nonexisting
      'Kategorie existiert nicht.'
    end

    def message_parent_nonexisting
      'Übergeordnetes Attribut existiert nicht.'
    end

    def message_parent_wrong_root
      'Ein übergeordnetes Attribut muss zur selben Kategorie gehören.'
    end

    def message_item_sub_of_sub
      'Ein Attribut kann nicht Unterattribut eines Unterattributs sein.'
    end

    def message_sub_of_itself
      'Ein Attribut kann nicht sein Unterattribut sein.'
    end

    def message_sub_cannot_be_nested
      'Ein Attribut mit Unterattributen kann nicht verschachtelt werden.'
    end

    # FacetItemTest

    test 'update facet item with new parent and facet' do
      facet = create(:facet)
      facet2 = create(:facet)
      parent = create(:facet_item, facet: facet)
      parent2 = create(:facet_item, facet: facet2)
      facet_item = create(:facet_item, facet: facet)

      facet_item = save_item(id: facet_item.id, parent_id: parent.id, title: 'changed facet item')
      assert_equal facet_item.facet_id, facet.id
      assert_equal facet_item.parent_id, parent.id

      facet_item = save_item(facet_id: facet2.id, id: facet_item.id, parent_id: parent2.id, title: 'changed facet item')
      assert_equal facet_item.facet_id, facet2.id
      assert_equal facet_item.parent_id, parent2.id

      parent2.reload
      assert_equal [facet_item], parent2.sub_items
    end

    test 'update sub_items facet on update facet_item facet' do
      facet = create(:facet_with_items_and_sub_items)
      parent = facet.facet_items.select { |item| item.sub_items.count > 0 }.first
      sub_item = parent.sub_items.first
      sub_item2 = parent.sub_items.last
      facet2 = create(:facet)

      assert_equal facet.id, parent.facet_id
      assert_equal facet.id, sub_item.facet_id
      assert_equal facet.id, sub_item2.facet_id

      save_item(facet_id: facet2.id, id: parent.id)

      parent.reload
      sub_item.reload
      sub_item2.reload

      assert_equal facet2.id, parent.facet_id
      assert_equal facet2.id, sub_item.facet_id
      assert_equal facet2.id, sub_item2.facet_id
    end

    test 'should only allow to add owners of allowed types' do
      facet = create(:facet_with_items, owner_types: ['Orga'])
      item = facet.facet_items.first

      orga = create(:orga)
      event = create(:event)
      offer = create(:offer)

      assert_difference -> { ownerClass.count } do
        item.link_owner(orga)
      end

      assert_no_difference -> { ownerClass.count } do
        item.link_owner(event)
        item.link_owner(offer)
      end

      facet = create(:facet_with_items, owner_types: ['Orga', 'Offer'])
      item = facet.facet_items.first

      assert_difference -> { ownerClass.count }, 2 do
        item.link_owner(orga)
        item.link_owner(offer)
      end

      assert_no_difference -> { ownerClass.count } do
        item.link_owner(event)
      end
    end

  end
end
