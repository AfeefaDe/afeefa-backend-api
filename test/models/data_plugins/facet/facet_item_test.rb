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

    should 'throw error on update facet item with parent_id if sub_items are present' do
      facet = create(:facet)
      parent = create(:facet_item, facet: facet)
      sub_item = create(:facet_item, facet: facet)
      facet_item = create(:facet_item, facet: facet)
      facet_item.sub_items << sub_item

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        facet_item = save_facet_item(facet_id: facet.id, id: facet_item.id, parent_id: parent.id, title: 'changed facet item')
      }
      assert_match 'Ein Attribut mit Unterattributen kann nicht verschachtelt werden.', exception.message
    end

    should 'throw error on update facet item with parent_id if parent is sub_item' do
      facet = create(:facet)
      parent = create(:facet_item, facet: facet)
      sub_item = create(:facet_item, facet: facet)
      parent.sub_items << sub_item
      facet_item = create(:facet_item, facet: facet)

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        facet_item = save_facet_item(facet_id: facet.id, id: facet_item.id, parent_id: sub_item.id, title: 'changed facet item')
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

    private

    def save_facet_item(hash)
      DataPlugins::Facet::FacetItem.save_facet_item(ActionController::Parameters.new(hash))
    end

  end
end
