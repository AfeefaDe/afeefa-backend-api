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
          offer.serialize_lazy.as_json,
          offer2.serialize_lazy.as_json
        ]
      }
      assert_equal expected.deep_stringify_keys, json

      user.area = 'area2'
      get :index
      json = JSON.parse(response.body)
      expected = {
        data: [
          offer3.serialize_lazy.as_json,
          offer4.serialize_lazy.as_json
        ]
      }
      assert_equal expected.deep_stringify_keys, json
    end

    should 'create offer without owner' do
      assert_no_difference -> { DataModules::Offer::OfferOwner.count } do
        assert_difference -> { DataModules::Offer::Offer.count } do
          post :create, params: { title: 'Neues Angebot', short_description: 'Beschreibung' }
          assert_response :created
        end
      end

      json = JSON.parse(response.body)
      offer = DataModules::Offer::Offer.last
      assert_equal @controller.current_api_v1_user.area, offer.area
      assert_equal JSON.parse(offer.to_json), json
    end


    should 'allow to create offer with existing title' do
      offer = create(:offer, title: 'test')
      offer2 = create(:offer, title: 'test')

      assert_equal offer.title, offer2.title
    end

    should 'create offer with owners' do
      actor = create(:orga)
      actor2 = create(:orga_with_random_title)

      assert_difference -> { DataModules::Offer::OfferOwner.count }, 2 do
        assert_difference -> { DataModules::Offer::Offer.count } do
          post :create, params: { title: 'Neues Angebot', short_description: 'Beschreibung', owners: [actor.id, actor2.id] }
          assert_response :created
        end
      end

      json = JSON.parse(response.body)
      offer = DataModules::Offer::Offer.last
      assert_equal JSON.parse(offer.to_json), json
    end


    should 'create offer with owners and link contact of first owner' do
      actor = create(:orga)
      assert actor.linked_contact
      assert actor.contacts.first
      actor2 = create(:orga)
      assert actor2.linked_contact
      assert actor2.contacts.first

      assert_difference -> { DataModules::Offer::OfferOwner.count }, 2 do
        assert_difference -> { DataModules::Offer::Offer.count } do
          post :create, params: { title: 'Neues Angebot', short_description: 'Beschreibung', owners: [actor.id, actor2.id] }
          assert_response :created
        end
      end

      json = JSON.parse(response.body)
      offer = DataModules::Offer::Offer.last
      assert_equal JSON.parse(offer.to_json), json

      assert_equal actor.linked_contact, offer.linked_contact
      assert_equal actor.contacts.first, offer.linked_contact
      assert_empty offer.contacts
    end

    should 'raise exception if create offer with wrong actor' do
      assert_no_difference -> { DataModules::Offer::OfferOwner.count } do
        assert_no_difference -> { DataModules::Offer::Offer.count } do
          post :create, params: { title: 'Neues Angebot', short_description: 'Beschreibung', owners: [134] }
          assert_response :unprocessable_entity
        end
      end
    end

    should 'raise exception if create offer with missing data' do
      assert_no_difference -> { DataModules::Offer::OfferOwner.count } do
        assert_no_difference -> { DataModules::Offer::Offer.count } do
          post :create, params: {}
          assert_response :unprocessable_entity
        end
        json = JSON.parse(response.body)
        assert_equal(
          [
            'Titel - fehlt',
            'Kurzbeschreibung - fehlt',
          ],
          json['errors']
        )
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

      attributes = ["title", 'active', 'created_at', 'updated_at']
      relationships = ["facet_items", "navigation_items"]

      get :index
      json = JSON.parse(response.body)['data'][0]

      assert_same_elements attributes, json['attributes'].keys
      assert_same_elements relationships, json['relationships'].keys

      relationships << 'owners' << 'annotations' << 'creator' << 'last_editor'

      get :index, params: { ids: [offer.id] }
      json = JSON.parse(response.body)['data'][0]

      assert_same_elements attributes, json['attributes'].keys
      assert_same_elements relationships, json['relationships'].keys

      relationships << 'contacts'
      attributes << 'short_description' << 'description' << 'image_url' << 'contact_spec'

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
          assert_response :unprocessable_entity
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
          assert_response :unprocessable_entity
          assert response.body.blank?
        end
      end
    end

    should 'convert actor and its relations to offer' do
      actor = create(:orga_without_contacts)
      assert actor.contacts.blank?
      assert actor.locations.blank?

      # old parents
      actor_initiator1 = create(:orga)
      actor.project_initiators << actor_initiator1
      actor_initiator2 = create(:orga)
      actor.project_initiators << actor_initiator2
      assert_equal [actor_initiator1, actor_initiator2], actor.project_initiators

      # offers, events, projects
      event1 = create(:event)
      actor.events << event1
      event2 = create(:event)
      actor.events << event2
      assert_equal [event1, event2], actor.events

      offer1 = create(:offer)
      actor.offers << offer1
      offer2 = create(:offer)
      actor.offers << offer2
      assert_equal [offer1, offer2], actor.offers

      project1 = create(:orga)
      actor.projects << project1
      project2 = create(:orga)
      actor.projects << project2
      assert_equal [project1, project2], actor.projects

      # contact, location
      contact = create(:contact, owner: actor)
      location = create(:location, contact: contact, owner: actor) # location is owned by this contact
      # link location to contact
      location.linking_contacts << contact
      # link contact to actor
      actor.update(linked_contact: contact)

      actor.reload

      assert_equal actor, contact.owner
      assert_equal contact, actor.contacts.first
      assert_equal contact, actor.linked_contact

      assert_equal actor, location.owner
      assert_equal contact, location.linking_contacts.first
      assert_equal location, actor.locations.first
      assert_equal location, contact.location

      # navigation
      navigation_item = create(:fe_navigation_item)
      actor.navigation_items << navigation_item
      assert_equal [navigation_item], actor.navigation_items

      # annotations
      annotation1 = Annotation.create!(detail: 'annotation123', entry: actor, annotation_category: AnnotationCategory.first)
      annotation2 = Annotation.create!(detail: 'annotation456', entry: actor, annotation_category: AnnotationCategory.first)
      assert_equal [annotation2, annotation1], actor.annotations

      new_offer_owner = create(:orga)

      new_offer = nil

      assert_difference -> { Orga.count }, -1 do
        assert_difference -> { DataModules::Offer::Offer.count } do
          assert_no_difference -> { Event.count } do
            assert_no_difference -> { Annotation.count } do
              assert_no_difference -> { DataPlugins::Location::Location.count } do
                assert_no_difference -> { DataPlugins::Contact::Contact.count } do
                  # before 2parents-actor->2projects
                  # after parent1->2projects parent2->2projects
                  assert_no_difference -> { DataModules::Actor::ActorRelation.count } do
                    post :convert_from_actor, params: {
                      actorId: actor.id,
                      owners: [actor_initiator1.id, new_offer_owner.id],
                      title: 'Neuer Titel',
                      short_description: 'Neue Kurzbeschreibung',
                      description: 'Neue Beschreibung',
                      image_url: 'http://image.jpg'
                    }
                    assert_response :created
                    json = JSON.parse(response.body)
                    new_offer = DataModules::Offer::Offer.last
                    assert_equal JSON.parse(new_offer.to_json), json
                    assert_equal 'Neue Kurzbeschreibung', new_offer.short_description
                    assert_equal 'Neue Beschreibung', new_offer.description
                  end
                end
              end
            end
          end
        end
      end

      actor_initiator1.reload
      actor_initiator2.reload
      new_offer_owner.reload
      contact.reload
      location.reload

      # owners
      assert_equal [actor_initiator1, new_offer_owner], new_offer.owners

      # offers, events, projects
      assert_equal [event1, event2].sort_by { |x| x.id }, actor_initiator1.events.order(:id)
      assert_equal [event1, event2].sort_by { |x| x.id }, new_offer_owner.events.order(:id)

      assert_equal [new_offer, offer1, offer2].sort_by { |x| x.id }, actor_initiator1.offers.order(:id)
      assert_equal [new_offer, offer1, offer2].sort_by { |x| x.id }, new_offer_owner.offers.order(:id)

      assert_equal [project1, project2].sort_by { |x| x.id }, actor_initiator1.projects.order(:id)
      assert_equal [project1, project2].sort_by { |x| x.id }, new_offer_owner.projects.order(:id)
      assert_nil actor_initiator2.projects.first

      # contact, location
      assert_equal contact, new_offer.contacts.first
      assert_equal new_offer, contact.owner
      assert_equal contact, new_offer.linked_contact

      assert_equal location, new_offer.locations.first
      assert_equal new_offer, location.owner

      # navigation
      assert_equal [navigation_item], new_offer.navigation_items

      # annotations
      assert_equal [annotation2, annotation1], new_offer.annotations
    end
  end
end
