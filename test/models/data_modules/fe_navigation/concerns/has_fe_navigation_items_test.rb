require 'test_helper'

module DataPlugins::FeNavigationItem
  class HasFeNavigationItemsTest < ActiveSupport::TestCase

    setup do
      @navigation = create(:fe_navigation)
      @navigation_item = create(:fe_navigation_item, navigation: @navigation)
      @navigation_item2 = create(:fe_navigation_item, navigation: @navigation)
    end

    should 'deliver navigation items for orga' do
      orga = create(:orga)

      assert_equal [], orga.navigation_items.all

      @navigation_item.orgas << orga
      @navigation_item2.orgas << orga

      assert_equal [@navigation_item, @navigation_item2], orga.navigation_items.all
    end

    should 'deliver navigation items for event' do
      event = create(:event)

      assert_equal [], event.navigation_items.all

      @navigation_item.events << event
      @navigation_item2.events << event

      assert_equal [@navigation_item, @navigation_item2], event.navigation_items.all
    end

    should 'remove navigation_item owner links on remove orga' do
      orga = create(:orga)
      @navigation_item.link_owner(orga)
      @navigation_item2.link_owner(orga)

      assert_no_difference 'DataModules::FeNavigation::FeNavigationItem.count' do
        assert_difference 'DataModules::FeNavigation::FeNavigationItemOwner.count', -2 do
          assert_difference 'Orga.count', -1 do
            orga.destroy!
          end
        end
      end
    end

    should 'remove navigation_item owner links on remove offer' do
      offer = create(:offer)
      @navigation_item.link_owner(offer)
      @navigation_item2.link_owner(offer)

      assert_no_difference 'DataModules::FeNavigation::FeNavigationItem.count' do
        assert_difference 'DataModules::FeNavigation::FeNavigationItemOwner.count', -2 do
          assert_difference 'DataModules::Offer::Offer.count', -1 do
            offer.destroy!
          end
        end
      end
    end

    should 'remove navigation_item owner links on remove event' do
      event = create(:event)
      @navigation_item.link_owner(event)
      @navigation_item2.link_owner(event)

      assert_no_difference 'DataModules::FeNavigation::FeNavigationItem.count' do
        assert_difference 'DataModules::FeNavigation::FeNavigationItemOwner.count', -2 do
          assert_difference 'Event.count', -1 do
            event.destroy!
          end
        end
      end
    end

    should 'remove navigation_item owner links on remove facet item' do
      facet = create(:facet_with_items)
      facet_item = facet.facet_items.first
      @navigation_item.link_owner(facet_item)
      @navigation_item2.link_owner(facet_item)

      assert_no_difference 'DataModules::FeNavigation::FeNavigationItem.count' do
        assert_difference 'DataModules::FeNavigation::FeNavigationItemOwner.count', -2 do
          assert_difference 'DataPlugins::Facet::FacetItem.count', -1 do
            facet_item.destroy!
          end
        end
      end
    end

  end
end
