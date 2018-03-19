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
      assert_response :unprocessable_entity
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
  end

end
