require 'test_helper'

class DataPlugins::Facet::V1::FacetItemsControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get facet items' do
      DataPlugins::Facet::FacetItem.delete_all
      10.times do
        create(:facet_item)
      end

      get :index
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Hash, json
      assert_kind_of Array, json['data']
      assert_equal 10, json['data'].count
    end

    should 'get facet items for facet_id' do
      DataPlugins::Facet::FacetItem.delete_all
      facet = create(:facet)
      10.times do |i|
        if i % 2 == 0
          create(:facet_item)
        else
          create(:facet_item, facet_id: facet.id)
        end
      end

      get :index, params: { filter: { facet_id: facet.id.to_s } }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Hash, json
      assert_kind_of Array, json['data']
      assert_equal 5, json['data'].count
    end

    should 'get single facet item' do
      facet_item = create(:facet_item)

      get :show, params: { id: facet_item.id }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_equal JSON.parse(facet_item.to_json), json['data']
    end

    should 'create facet item' do
      assert_difference -> { DataPlugins::Facet::FacetItem.count } do
        post :create, params: { title: 'new facet' }
        assert_response :created
      end
      json = JSON.parse(response.body)
      facet_item = DataPlugins::Facet::FacetItem.last
      assert_equal JSON.parse(facet_item.to_json), json
    end

    should 'update facet item' do
      facet_item = create(:facet_item)

      assert_no_difference -> { DataPlugins::Facet::FacetItem.count } do
        patch :update, params: { id: facet_item.id, title: 'changed facet' }
        assert_response :ok
      end
      json = JSON.parse(response.body)
      facet_item.reload
      assert_equal JSON.parse(facet_item.to_json), json
    end

    should 'remove facet item' do
      facet_item = create(:facet_item)

      assert_difference -> { DataPlugins::Facet::FacetItem.count }, -1 do
        delete :destroy, params: { id: facet_item.id }
        assert_response 200
      end
      assert response.body.blank?
    end
  end

end
