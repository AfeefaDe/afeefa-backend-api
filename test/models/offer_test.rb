require 'test_helper'

class OfferTest < ActiveSupport::TestCase

  should 'render json' do
    assert_equal(DataModules::Offer::Offer.attribute_whitelist_for_json.sort,
      JSON.parse(DataModules::Offer::Offer.new.to_json)['attributes'].symbolize_keys.keys.sort)
  end

  should 'complain on missing actor on create' do
    offer = DataModules::Offer::Offer.new
    assert_not offer.valid?
    assert_match 'Kein Eigentümer', offer.errors[:actor_id].first

    actor = create(:event)
    offer = DataModules::Offer::Offer.new(actor_id: actor.id)
    assert_not offer.valid?
    assert_match 'Kein Eigentümer', offer.errors[:actor_id].first

    actor = create(:orga, title: 'valid_actor')
    offer = DataModules::Offer::Offer.new(actor_id: actor.id)
    assert offer.valid?
  end

  should 'associate new offer with given actor' do
    actor = create(:orga)

    assert_difference -> { DataModules::Offer::OwnerOffer.count } do
      offer = DataModules::Offer::Offer.create(actor_id: actor.id)

      assert_equal actor, offer.actors.first
      assert_equal offer, actor.offers.first
    end
  end

  should 'delete actor association on destroy' do
    actor = create(:orga)
    offer = DataModules::Offer::Offer.create(actor_id: actor.id)

    assert_difference -> { DataModules::Offer::OwnerOffer.count }, -1 do
      offer.destroy

      assert_nil offer.actors.first
      assert_nil actor.offers.first
    end
  end

end
