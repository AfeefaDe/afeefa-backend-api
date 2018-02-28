require 'test_helper'

module DataPlugins::Facet
  class FacetTest < ActiveSupport::TestCase

    should 'validate facet' do
      facet = create(:facet_with_items, facet_items_count: 2)
      assert_equal 2, facet.facet_items.count
      assert_equal facet.facet_items.first.title,
        JSON.parse(facet.to_json)['relationships']['facet_items']['data'].first['attributes']['title']
    end

  end
end
