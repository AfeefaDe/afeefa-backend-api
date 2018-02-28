require 'test_helper'

module DataPlugins::Facet
  class FacetItemTest < ActiveSupport::TestCase

    should 'validate facet' do
      facet_item = FacetItem.new
      assert_not facet_item.valid?
      assert facet_item.errors[:facet_id].present?
    end

  end
end
