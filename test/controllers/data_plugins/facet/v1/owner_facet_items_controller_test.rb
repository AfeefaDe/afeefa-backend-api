require 'test_helper'

class DataPlugins::Facet::V1::OwnerFacetItemsControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'link owner with facet item' do
      facet = create(:facet, owner_types: ['Orga'])
      facet_item = create(:facet_item, facet: facet)
      orga = create(:orga)

      assert_difference -> { DataPlugins::Facet::OwnerFacetItem.count } do
        post :link_facet_item, params: { owner_type: 'orgas', owner_id: orga.id, facet_item_id: facet_item.id }
        assert_response :created

        assert_equal facet_item, orga.facet_items.first
      end
      assert response.body.blank?
    end

    should 'link event with facet item' do
      facet = create(:facet, owner_types: ['Orga', 'Event'])
      facet_item = create(:facet_item, facet: facet)
      event = create(:event)

      assert_difference -> { DataPlugins::Facet::OwnerFacetItem.count } do
        post :link_facet_item, params: { owner_type: 'events', owner_id: event.id, facet_item_id: facet_item.id }
        assert_response :created

        assert_equal facet_item, event.facet_items.first
      end
      assert response.body.blank?
    end

    should 'link offer with facet item' do
      facet = create(:facet, owner_types: ['Orga', 'Offer'])
      facet_item = create(:facet_item, facet: facet)
      orga = create(:orga)
      offer = create(:offer, actor_id: orga.id)

      assert_difference -> { DataPlugins::Facet::OwnerFacetItem.count } do
        post :link_facet_item, params: { owner_type: 'offers', owner_id: offer.id, facet_item_id: facet_item.id }
        assert_response :created

        assert_equal facet_item, offer.facet_items.first
      end
      assert response.body.blank?
    end

    should 'call facet_item.link_owner on link facet item' do
      facet = create(:facet_with_items, owner_types: ['Orga'])
      facet_item = facet.facet_items.first

      orga = create(:orga)

      DataPlugins::Facet::FacetItem.any_instance.expects(:link_owner).with(orga)

      post :link_facet_item, params: { owner_type: 'orgas', owner_id: orga.id, facet_item_id: facet_item.id }
    end

    should 'throw error if linking owner which is not supported by facet' do
      facet = create(:facet, owner_types: ['Orga'])
      facet_item = create(:facet_item, facet: facet)
      event = create(:event)

      assert_no_difference -> { DataPlugins::Facet::OwnerFacetItem.count } do
        post :link_facet_item, params: { owner_type: 'events', owner_id: event.id, facet_item_id: facet_item.id }
        assert_response :unprocessable_entity
      end
      assert response.body.blank?
    end

    should 'throw error on link facet item again' do
      facet = create(:facet, owner_types: ['Orga'])
      facet_item = create(:facet_item, facet: facet)
      orga = create(:orga)

      post :link_facet_item, params: { owner_type: 'orgas', owner_id: orga.id, facet_item_id: facet_item.id }

      assert_no_difference -> { DataPlugins::Facet::OwnerFacetItem.count } do
        post :link_facet_item, params: { owner_type: 'orgas', owner_id: orga.id, facet_item_id: facet_item.id }
        assert_response :unprocessable_entity
      end
      assert response.body.blank?
    end

    should 'unlink facet item' do
      facet = create(:facet, owner_types: ['Orga'])
      facet_item = create(:facet_item, facet: facet)
      orga = create(:orga)

      post :link_facet_item, params: { owner_type: 'orgas', owner_id: orga.id, facet_item_id: facet_item.id }

      assert_difference -> { DataPlugins::Facet::OwnerFacetItem.count }, -1 do
        delete :unlink_facet_item, params: { owner_type: 'orgas', owner_id: orga.id, facet_item_id: facet_item.id }
        assert_response :ok

        assert_nil orga.facet_items.first
      end
      assert response.body.blank?
    end

    should 'call facet_item.unlink_owner on link facet item' do
      facet = create(:facet_with_items, owner_types: ['Orga'])
      facet_item = facet.facet_items.first

      orga = create(:orga)

      post :link_facet_item, params: { owner_type: 'orgas', owner_id: orga.id, facet_item_id: facet_item.id }

      DataPlugins::Facet::FacetItem.any_instance.expects(:unlink_owner).with(orga)

      delete :unlink_facet_item, params: { owner_type: 'orgas', owner_id: orga.id, facet_item_id: facet_item.id }
    end

    should 'throw error on unlink facet item again' do
      facet = create(:facet, owner_types: ['Orga'])
      facet_item = create(:facet_item, facet: facet)
      orga = create(:orga)

      post :link_facet_item, params: { owner_type: 'orgas', owner_id: orga.id, facet_item_id: facet_item.id }
      delete :unlink_facet_item, params: { owner_type: 'orgas', owner_id: orga.id, facet_item_id: facet_item.id }

      assert_no_difference -> { DataPlugins::Facet::OwnerFacetItem.count } do
        delete :unlink_facet_item, params: { owner_type: 'orgas', owner_id: orga.id, facet_item_id: facet_item.id }
        assert_response :not_found
      end
      assert response.body.blank?
    end

    should 'get linked facet items' do
      facet = create(:facet, owner_types: ['Orga'])
      facet_item = create(:facet_item, facet: facet)
      facet_item2 = create(:facet_item, facet: facet)
      orga = create(:orga)

      post :link_facet_item, params: { owner_type: 'orgas', owner_id: orga.id, facet_item_id: facet_item.id }
      post :link_facet_item, params: { owner_type: 'orgas', owner_id: orga.id, facet_item_id: facet_item2.id }

      get :get_linked_facet_items, params: { owner_type: 'orgas', owner_id: orga.id }
      assert_response :ok

      json = JSON.parse(response.body)
      assert_equal 2, json.count
      assert_equal JSON.parse(facet_item.to_json), json.first
      assert_equal JSON.parse(facet_item2.to_json), json[1]
    end

  end
end
