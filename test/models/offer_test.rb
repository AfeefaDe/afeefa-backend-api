require 'test_helper'

class OfferTest < ActiveSupport::TestCase

  test 'create offer triggers fapi cache' do
    FapiCacheJob.any_instance.expects(:update_entry).with(instance_of(DataModules::Offer::Offer)).at_least_once

    DataModules::Offer::Offer.new.save(validate: false)
  end

  test 'set creator and editor on create and update' do
    user = Current.user
    offer = create(:offer)

    assert_equal user, offer.creator
    assert_equal user, offer.last_editor
  end

  test 'set editor on update' do
    user = Current.user
    offer = create(:offer)
    assert_equal user, offer.last_editor

    user2 = create(:user)
    Current.stubs(:user).returns(user2)
    offer.update(title: 'new')
    assert_equal user2, offer.last_editor
  end

  test 'update offer triggers fapi cache' do
    offer = create(:offer)

    FapiCacheJob.any_instance.expects(:update_entry).with(offer)

    offer.update(area: 'kumbutzburg')
  end

  test 'remove offer triggers fapi cache' do
    offer = create(:offer)

    FapiCacheJob.any_instance.expects(:delete_entry).with(offer)

    offer.destroy
  end

  test 'render json' do
    assert_equal(DataModules::Offer::Offer.attribute_whitelist_for_json.sort,
      JSON.parse(DataModules::Offer::Offer.new.to_json)['attributes'].symbolize_keys.keys.sort)
  end

  test 'delete actor association on destroy' do
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
