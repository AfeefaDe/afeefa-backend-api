require 'test_helper'

module DataPlugins::Facet
  class HasFacetItemsTest < ActiveSupport::TestCase

    setup do
      @facet = create(:facet, owner_types: ['Orga'])
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
  end
end
