require 'test_helper'

class OfferTest < ActiveSupport::TestCase

  should 'render json' do
    assert_equal(DataModules::Offer::Offer.attribute_whitelist_for_json.sort,
      JSON.parse(DataModules::Offer::Offer.new.to_json)['attributes'].symbolize_keys.keys.sort)
  end

  should 'delete actor association on destroy' do
    actor = create(:orga)
    offer = create(:offer, actors: [actor.id])

    assert_no_difference -> { Orga.count } do
      assert_difference -> { DataModules::Offer::OfferOwner.count }, -1 do
        offer.destroy

        assert_nil offer.owners.first
        assert_nil actor.offers.first
      end
    end
  end

end
