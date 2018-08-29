require 'test_helper'

class DataModules::Offer::V1::OffersControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get offers by area' do
      offer = create(:offer, area: 'area1')
      offer2 = create(:offer, area: 'area1')
      offer3 = create(:offer, area: 'area2')
      offer4 = create(:offer, area: 'area2')

      user = @controller.current_api_v1_user
      user.area = 'area1'

      get :index
      json = JSON.parse(response.body)
      expected = {
        data: [
          offer.to_hash(
            attributes: DataModules::Offer::Offer.lazy_attributes_for_json,
            relationships: DataModules::Offer::Offer.lazy_relations_for_json
          ),
          offer2.to_hash(
            attributes: DataModules::Offer::Offer.lazy_attributes_for_json,
            relationships: DataModules::Offer::Offer.lazy_relations_for_json
          )
        ]
      }
      assert_equal expected.deep_stringify_keys, json

      user.area = 'area2'
      get :index
      json = JSON.parse(response.body)
      expected = {
        data: [
          offer3.to_hash(
            attributes: DataModules::Offer::Offer.lazy_attributes_for_json,
            relationships: DataModules::Offer::Offer.lazy_relations_for_json
          ),
          offer4.to_hash(
            attributes: DataModules::Offer::Offer.lazy_attributes_for_json,
            relationships: DataModules::Offer::Offer.lazy_relations_for_json
          )
        ]
      }
      assert_equal expected.deep_stringify_keys, json
    end

    should 'create offer without owner' do
      actor = create(:orga)

      assert_no_difference -> { DataModules::Offer::OfferOwner.count } do
        assert_difference -> { DataModules::Offer::Offer.count } do
          post :create, params: { title: 'Neues Angebot' }
          assert_response :created
        end
      end

      json = JSON.parse(response.body)
      offer = DataModules::Offer::Offer.last
      assert_equal @controller.current_api_v1_user.area, offer.area
      assert_equal JSON.parse(offer.to_json), json
    end

    should 'create offer with owners' do
      actor = create(:orga)
      actor2 = create(:orga_with_random_title)

      assert_difference -> { DataModules::Offer::OfferOwner.count }, 2 do
        assert_difference -> { DataModules::Offer::Offer.count } do
          post :create, params: { title: 'Neues Angebot', actors: [actor.id, actor2.id] }
          assert_response :created
        end
      end

      json = JSON.parse(response.body)
      offer = DataModules::Offer::Offer.last
      assert_equal JSON.parse(offer.to_json), json
    end

    should 'raise exception if create offer with wrong actor' do
      assert_no_difference -> { DataModules::Offer::OfferOwner.count } do
        assert_no_difference -> { DataModules::Offer::Offer.count } do
          post :create, params: { title: 'Neues Angebot', actors: [134] }
          assert_response :unprocessable_entity
        end
      end
    end

    should 'update offer' do
      actor = create(:orga)
      offer = create(:offer, actors: [actor.id])

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
      offer = create(:offer, actors: [actor.id])

      assert_difference -> { DataModules::Offer::OfferOwner.count }, -1 do
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

    should 'deliver owners with different detail granularity' do
      actor = create(:orga)
      offer = create(:offer, actors: [actor.id])

      get :index
      json = JSON.parse(response.body)['data'][0]
      assert_nil json['relationships']['owners']

      get :index, params: { ids: [offer.id] }
      json = JSON.parse(response.body)['data'][0]
      assert_equal 1, json['relationships']['owners']['data'][0]['attributes'].count
      assert_nil json['relationships']['owners']['data'][0]['attributes']['count_offers']

      get :show, params: { id: offer.id }
      json = JSON.parse(response.body)['data']
      assert_operator 1, :<, json['relationships']['owners']['data'][0]['attributes'].count
      assert_equal 1, json['relationships']['owners']['data'][0]['attributes']['count_offers']
    end

    should 'deliver attributes and relations in show and index' do
      actor = create(:orga)
      offer = create(:offer, actors: [actor.id])

      attributes = ["title"]
      relationships = ["facet_items", "navigation_items"]

      get :index
      json = JSON.parse(response.body)['data'][0]

      assert_same_elements attributes, json['attributes'].keys
      assert_same_elements relationships, json['relationships'].keys

      relationships << 'owners'
      attributes << 'description'

      get :index, params: { ids: [offer.id] }
      json = JSON.parse(response.body)['data'][0]

      assert_same_elements attributes, json['attributes'].keys
      assert_same_elements relationships, json['relationships'].keys

      get :show, params: { id: offer.id }
      json = JSON.parse(response.body)['data']

      assert_same_elements attributes, json['attributes'].keys
      assert_same_elements relationships, json['relationships'].keys

    end

    should 'link owners' do
      owner = create(:orga)
      owner2 = create(:orga_with_random_title)
      offer = create(:offer)

      assert_no_difference -> { Orga.count } do
        assert_difference -> { DataModules::Offer::OfferOwner.count }, 2 do
          post :link_owners, params: { id: offer.id, actors: [owner.id, owner2.id] }
          assert_response :created, response.body
          assert response.body.blank?
        end
      end

      assert_equal offer, owner.offers.first
      assert_equal offer, owner2.offers.first
      assert_equal [owner, owner2], offer.owners

      assert_no_difference -> { Orga.count } do
        assert_difference -> { DataModules::Offer::OfferOwner.count }, -1 do
          post :link_owners, params: { id: offer.id, actors: [owner2.id] }
          assert_response :created, response.body
          assert response.body.blank?
        end
      end

      offer.reload
      assert_equal [], owner.offers
      assert_equal offer, owner2.offers.first
      assert_equal [owner2], offer.owners

      assert_no_difference -> { Orga.count } do
        assert_difference -> { DataModules::Offer::OfferOwner.count }, -1 do
          post :link_owners, params: { id: offer.id, actors: [] }
          assert_response :created, response.body
          assert response.body.blank?
        end
      end

      offer.reload
      assert_equal [], owner.offers
      assert_equal [], owner2.offers
      assert_equal [], offer.owners
    end


    should 'throw error on linking nonexisting owner' do
      owner = create(:orga)
      offer = create(:offer)

      assert_no_difference -> { Orga.count } do
        assert_no_difference -> { DataModules::Offer::OfferOwner.count } do
          post :link_owners, params: { id: offer.id, actors: [owner.id, 2341] }
          assert_response :unprocessable_entity, response.body
          assert response.body.blank?
        end
      end
    end

    should 'throw error on linking owner of different area' do
      owner = create(:orga)
      owner2 = create(:orga_with_random_title, area: 'xyzabc')
      offer = create(:offer)

      assert_no_difference -> { Orga.count } do
        assert_no_difference -> { DataModules::Offer::OfferOwner.count } do
          post :link_owners, params: { id: offer.id, actors: [owner.id, owner2.id] }
          assert_response :unprocessable_entity, response.body
          assert response.body.blank?
        end
      end
    end

  end
end
