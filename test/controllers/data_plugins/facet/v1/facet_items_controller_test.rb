require 'test_helper'

class DataPlugins::Facet::V1::FacetItemsControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get facet items' do
      facet = create(:facet)

      DataPlugins::Facet::FacetItem.delete_all
      10.times do
        create(:facet_item, facet: facet)
      end

      get :index, params: { facet_id: facet.id }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Hash, json
      assert_kind_of Array, json['data']
      assert_equal 10, json['data'].count
    end

    should 'get single facet item' do
      facet = create(:facet)
      facet_item = create(:facet_item, facet: facet)

      get :show, params: { facet_id: facet.id, id: facet_item.id }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_equal JSON.parse(facet_item.to_json), json['data']
    end

    should 'create facet item' do
      facet = create(:facet)
      assert_difference -> { DataPlugins::Facet::FacetItem.count } do
        post :create, params: { facet_id: facet.id, title: 'new facet item' }
        assert_response :created
      end
      json = JSON.parse(response.body)
      facet_item = DataPlugins::Facet::FacetItem.last
      assert_equal JSON.parse(facet_item.to_json), json
    end

    should 'throw error on create with wrong params' do
      post :create, params: { facet_id: 1, title: 'new facet item' }
      assert_response :not_found
    end

    should 'update facet item' do
      facet = create(:facet)
      facet_item = create(:facet_item, facet: facet)

      assert_no_difference -> { DataPlugins::Facet::FacetItem.count } do
        patch :update, params: { facet_id: facet.id, id: facet_item.id, title: 'changed facet item' }
        assert_response :ok
      end

      json = JSON.parse(response.body)
      facet_item.reload
      assert_equal JSON.parse(facet_item.to_json), json
    end

    should 'update facet item with new facet and parent' do
      facet = create(:facet)
      facet2 = create(:facet)
      parent2 = create(:facet_item, facet: facet2)
      facet_item = create(:facet_item, facet: facet)

      assert_no_difference -> { DataPlugins::Facet::FacetItem.count } do
        patch :update, params: { facet_id: facet.id, id: facet_item.id, new_facet_id: facet2.id, parent_id: parent2.id, title: 'changed facet item' }
        assert_response :ok
      end

      json = JSON.parse(response.body)
      facet_item.reload
      assert_equal facet_item.facet_id, facet2.id
      assert_equal facet_item.parent_id, parent2.id
      assert_equal JSON.parse(facet_item.to_json), json
    end

    should 'throw error on update facet item with wrong params' do
      facet = create(:facet)
      facet_item = create(:facet_item, facet: facet)

      patch :update, params: { facet_id: facet.id, id: facet_item.id, parent_id: 123, title: 'changed facet item' }
      assert_response :unprocessable_entity
    end

    should 'remove facet item' do
      facet = create(:facet)
      facet_item = create(:facet_item, facet: facet)

      assert_difference -> { DataPlugins::Facet::FacetItem.count }, -1 do
        delete :destroy, params: { facet_id: facet.id, id: facet_item.id }
        assert_response 200
      end
      assert response.body.blank?
    end

    should 'get linked owners' do
      facet = create(:facet, owner_types: ['Orga'])
      facet_item = create(:facet_item, facet: facet)
      orga = create(:orga)
      orga2 = create(:orga, title: 'another orga')

      facet_item.link_owner(orga)
      facet_item.link_owner(orga2)

      get :get_linked_owners, params: { facet_id: facet.id, id: facet_item.id }
      assert_response :ok

      json = JSON.parse(response.body)
      assert_equal 2, json.count

      assert_equal orga.to_hash(attributes: [:title], relationships: nil).deep_stringify_keys, json.first
      assert_equal orga2.to_hash(attributes: [:title], relationships: nil).deep_stringify_keys, json[1]
    end

    should 'not deliver owners multiple times if also added to sub items' do
      facet = create(:facet_with_items_and_sub_items, owner_types: ['Orga'])

      parent = facet.facet_items.select { |item| item.parent == nil }.first
      sub_item = parent.sub_items.first

      orga = create(:orga)
      sub_item.link_owner(orga)

      assert_equal [parent, sub_item], orga.facet_items

      get :get_linked_owners, params: { facet_id: facet.id, id: parent.id }
      assert_response :ok

      json = JSON.parse(response.body)
      assert_equal 1, json.count

      assert_equal orga.to_hash(attributes: [:title], relationships: nil).deep_stringify_keys, json.first
    end

    should 'link multiple owners with facet item' do
      facet = create(:facet, owner_types: ['Orga'])
      facet_item = create(:facet_item, facet: facet)
      orga = create(:orga)
      orga2 = create(:orga, title: 'another orga')

      assert_difference -> { DataPlugins::Facet::OwnerFacetItem.count }, 2 do
        post :link_owners, params: {
          facet_id: facet.id, id: facet_item.id,
          owners: [
            { owner_type: 'orgas', owner_id: orga.id },
            { owner_type: 'orgas', owner_id: orga2.id }
          ]
        }
        assert_response :created

        assert_equal facet_item, orga.facet_items.first
        assert_equal facet_item, orga2.facet_items.first
      end
      assert response.body.blank?
    end

    should 'call facet_item.link_owner on link multiple owners' do
      facet = create(:facet_with_items, owner_types: ['Orga'])
      facet_item = facet.facet_items.first

      orga = create(:orga)
      orga2 = create(:orga, title: 'another orga')

      DataPlugins::Facet::FacetItem.any_instance.expects(:link_owner).with(orga)
      DataPlugins::Facet::FacetItem.any_instance.expects(:link_owner).with(orga2)

      post :link_owners, params: {
        facet_id: facet.id, id: facet_item.id,
        owners: [
          { owner_type: 'orgas', owner_id: orga.id },
          { owner_type: 'orgas', owner_id: orga2.id }
        ]
      }
    end

    should 'link owners of multiple types with facet item' do
      facet = create(:facet, owner_types: ['Orga', 'Event', 'Offer'])
      facet_item = create(:facet_item, facet: facet)
      orga = create(:orga)
      orga2 = create(:orga, title: 'another orga')
      event = create(:event, orga: orga2)
      offer = create(:offer, actor_id: orga.id)

      assert_difference -> { DataPlugins::Facet::OwnerFacetItem.count }, 4 do
        post :link_owners, params: {
          facet_id: facet.id, id: facet_item.id,
          owners: [
            { owner_type: 'orgas', owner_id: orga.id },
            { owner_type: 'orgas', owner_id: orga2.id },
            { owner_type: 'events', owner_id: event.id },
            { owner_type: 'offers', owner_id: offer.id }
          ]
        }
        assert_response :created

        assert_equal facet_item, orga.facet_items.first
        assert_equal facet_item, orga2.facet_items.first
        assert_equal facet_item, event.facet_items.first
        assert_equal facet_item, offer.facet_items.first
      end
      assert response.body.blank?
    end

    should 'not fail if linking multiple owners fails for one owner with already existing association' do
      facet = create(:facet, owner_types: ['Orga'])
      facet_item = create(:facet_item, facet: facet)
      orga = create(:orga)
      orga2 = create(:orga, title: 'another orga')

      facet_item.link_owner(orga)

      assert_difference -> { DataPlugins::Facet::OwnerFacetItem.count }, 1 do
        post :link_owners, params: {
          facet_id: facet.id, id: facet_item.id,
          owners: [
            { owner_type: 'orgas', owner_id: orga.id },
            { owner_type: 'orgas', owner_id: orga2.id }
          ]
        }
        assert_response :created

        assert_equal facet_item, orga.facet_items.first
        assert_equal facet_item, orga2.facet_items.first
      end
      assert response.body.blank?
    end

    should 'throw error if linking multiple owners fails for one owner which does not exist' do
      facet = create(:facet, owner_types: ['Orga'])
      facet_item = create(:facet_item, facet: facet)
      orga = create(:orga)

      assert_no_difference -> { DataPlugins::Facet::OwnerFacetItem.count } do
        post :link_owners, params: {
          facet_id: facet.id, id: facet_item.id,
          owners: [
            { owner_type: 'orgas', owner_id: orga.id },
            { owner_type: 'test', owner_id: 473 }
          ]
        }
        assert_response :unprocessable_entity

        assert_nil orga.facet_items.first
      end
      assert response.body.blank?
    end

    should 'throw error if linking multiple owners fails for all owners' do
      facet = create(:facet, owner_types: ['Event'])
      facet_item = create(:facet_item, facet: facet)
      orga = create(:orga)

      assert_no_difference -> { DataPlugins::Facet::OwnerFacetItem.count } do
        post :link_owners, params: {
          facet_id: facet.id, id: facet_item.id,
          owners: [
            { owner_type: 'orgas', owner_id: orga.id }
          ]
        }
        assert_response :unprocessable_entity

        assert_nil orga.facet_items.first
      end
      assert response.body.blank?
    end

    should 'not fail if linking multiple owners fails for one owner which type is not supported by facet' do
      facet = create(:facet, owner_types: ['Event'])
      facet_item = create(:facet_item, facet: facet)
      orga = create(:orga)
      event = create(:event)

      assert_difference -> { DataPlugins::Facet::OwnerFacetItem.count } do
        post :link_owners, params: {
          facet_id: facet.id, id: facet_item.id,
          owners: [
            { owner_type: 'orgas', owner_id: orga.id },
            { owner_type: 'events', owner_id: event.id }
          ]
        }
        assert_response :created

        assert_nil orga.facet_items.first
        assert_equal facet_item, event.facet_items.first
      end
      assert response.body.blank?
    end

    should 'unlink multiple owners from facet item' do
      facet = create(:facet, owner_types: ['Orga'])
      facet_item = create(:facet_item, facet: facet)
      orga = create(:orga)
      orga2 = create(:orga, title: 'another orga')

      facet_item.link_owner(orga)
      facet_item.link_owner(orga2)

      assert_difference -> { DataPlugins::Facet::OwnerFacetItem.count }, -2 do
        post :unlink_owners, params: {
          facet_id: facet.id, id: facet_item.id,
          owners: [
            { owner_type: 'orgas', owner_id: orga.id },
            { owner_type: 'orgas', owner_id: orga2.id }
          ]
        }
        assert_response :ok

        assert_nil orga.facet_items.first
        assert_nil orga2.facet_items.first
      end
      assert response.body.blank?
    end

    should 'call facet_item.unlink_owner on link multiple owners' do
      facet = create(:facet_with_items, owner_types: ['Orga'])
      facet_item = facet.facet_items.first

      orga = create(:orga)
      orga2 = create(:orga, title: 'another orga')

      facet_item.link_owner(orga)
      facet_item.link_owner(orga2)

      DataPlugins::Facet::FacetItem.any_instance.expects(:unlink_owner).with(orga)
      DataPlugins::Facet::FacetItem.any_instance.expects(:unlink_owner).with(orga2)

      post :unlink_owners, params: {
        facet_id: facet.id, id: facet_item.id,
        owners: [
          { owner_type: 'orgas', owner_id: orga.id },
          { owner_type: 'orgas', owner_id: orga2.id }
        ]
      }
    end

    should 'not fail if unlinking multiple owners fails for one owner without existing association' do
      facet = create(:facet_with_items, owner_types: ['Orga'])
      facet_item = facet.facet_items.first

      orga = create(:orga)
      orga2 = create(:orga, title: 'another orga')
      facet_item.link_owner(orga)

      assert_difference -> { DataPlugins::Facet::OwnerFacetItem.count }, -1 do
        post :unlink_owners, params: {
          facet_id: facet.id, id: facet_item.id,
          owners: [
            { owner_type: 'orgas', owner_id: orga.id },
            { owner_type: 'orgas', owner_id: orga2.id }
          ]
        }
        assert_response :ok

        assert_nil orga.facet_items.first
        assert_nil orga2.facet_items.first
      end
      assert response.body.blank?
    end

    should 'throw error if unlinking multiple owners fails for one nonexisting owner' do
      facet = create(:facet_with_items, owner_types: ['Orga'])
      facet_item = facet.facet_items.first

      orga = create(:orga)
      facet_item.link_owner(orga)

      assert_no_difference -> { DataPlugins::Facet::OwnerFacetItem.count } do
        post :unlink_owners, params: {
          facet_id: facet.id, id: facet_item.id,
          owners: [
            { owner_type: 'orgas', owner_id: orga.id },
            { owner_type: 'test', owner_id: 473 }
          ]
        }
        assert_response :unprocessable_entity
      end
      assert response.body.blank?
    end

    should 'throw error if unlinking multiple owners fails for all owners' do
      facet = create(:facet_with_items, owner_types: ['Orga'])
      facet_item = facet.facet_items.first

      orga = create(:orga)

      assert_no_difference -> { DataPlugins::Facet::OwnerFacetItem.count } do
        post :unlink_owners, params: {
          facet_id: facet.id, id: facet_item.id,
          owners: [
            { owner_type: 'orgas', owner_id: orga.id }
          ]
        }
        assert_response :unprocessable_entity
      end
      assert response.body.blank?
    end
  end

end
