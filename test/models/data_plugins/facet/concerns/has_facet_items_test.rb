require 'test_helper'

module DataPlugins::Facet
  class HasFacetItemsTest < ActiveSupport::TestCase

    setup do
      @facet = create(:facet, owner_types: ['Orga', 'Event', 'Offer'])
      @facet_item = create(:facet_item, facet: @facet)
      @facet_item2 = create(:facet_item, facet: @facet)
    end

    should 'deliver facet items for orga' do
      orga = create(:orga)

      assert_equal [], orga.facet_items.all

      @facet_item.orgas << orga
      @facet_item2.orgas << orga

      assert_equal [@facet_item, @facet_item2], orga.facet_items.all
    end

    should 'deliver facet items for event' do
      event = create(:event)

      assert_equal [], event.facet_items.all

      @facet_item.events << event
      @facet_item2.events << event

      assert_equal [@facet_item, @facet_item2], event.facet_items.all
    end

    should 'remove facet_item owner links on remove orga' do
      orga = create(:orga)
      @facet_item.link_owner(orga)
      @facet_item2.link_owner(orga)

      assert_no_difference 'DataPlugins::Facet::FacetItem.count' do
        assert_difference 'DataPlugins::Facet::FacetItemOwner.count', -2 do
          assert_difference 'Orga.count', -1 do
            orga.destroy!
          end
        end
      end
    end

    should 'remove facet_item owner links on remove offer' do
      offer = create(:offer)
      @facet_item.link_owner(offer)
      @facet_item2.link_owner(offer)

      assert_no_difference 'DataPlugins::Facet::FacetItem.count' do
        assert_difference 'DataPlugins::Facet::FacetItemOwner.count', -2 do
          assert_difference 'DataModules::Offer::Offer.count', -1 do
            offer.destroy!
          end
        end
      end
    end


    should 'remove facet_item owner links on remove event' do
      event = create(:event)
      @facet_item.link_owner(event)
      @facet_item2.link_owner(event)

      assert_no_difference 'DataPlugins::Facet::FacetItem.count' do
        assert_difference 'DataPlugins::Facet::FacetItemOwner.count', -2 do
          assert_difference 'Event.count', -1 do
            event.destroy!
          end
        end
      end
    end

  end
end
