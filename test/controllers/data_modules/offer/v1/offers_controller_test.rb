require 'test_helper'

class DataModules::Offer::V1::OffersControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'create offer with actor' do
      actor = create(:orga)

      assert_difference -> { DataModules::Offer::OwnerOffer.count } do
        assert_difference -> { DataModules::Offer::Offer.count } do
          post :create, params: { title: 'Neues Angebot', actor_id: actor.id }
          assert_response :created
        end
      end

      json = JSON.parse(response.body)
      offer = DataModules::Offer::Offer.last
      assert_equal JSON.parse(offer.to_json), json
    end

    should 'raise exception if create offer with wrong actor' do
      assert_no_difference -> { DataModules::Offer::OwnerOffer.count } do
        assert_no_difference -> { DataModules::Offer::Offer.count } do
          post :create, params: { title: 'Neues Angebot', actor_id: 134 }
          assert_response :unprocessable_entity
        end
      end
    end

    should 'update offer' do
      actor = create(:orga)
      offer = create(:offer, actor_id: actor.id)

      patch :update, params: { id: offer.id, titel: 'Neuer Name für Angebot' }
      assert_response :ok

      json = JSON.parse(response.body)
      offer = DataModules::Offer::Offer.last
      assert_equal JSON.parse(offer.to_json), json
    end

    should 'throw error if updating nonexistant offer' do
      patch :update, params: { id: 1123, titel: 'Neuer Name für Angebot' }
      assert_response :not_found
    end

    should 'delete offer' do
      actor = create(:orga)
      offer = create(:offer, actor_id: actor.id)

      assert_difference -> { DataModules::Offer::OwnerOffer.count }, -1 do
        assert_difference -> { DataModules::Offer::Offer.count }, -1 do
          delete :destroy, params: { id: offer.id }
          assert_response :ok
        end
      end
    end

    should 'throw error if deleting nonexisting offer' do
      delete :destroy, params: { id: 123 }
      assert_response :not_found
    end

  end
end
