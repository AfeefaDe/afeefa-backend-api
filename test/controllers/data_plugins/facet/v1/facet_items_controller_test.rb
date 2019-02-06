require 'test_helper'

class DataPlugins::Facet::V1::FacetItemsControllerTest < ActionController::TestCase

  include ActsAsFacetItemControllerTest

  setup do
    stub_current_user
  end

  test 'get items' do
    facet = create(:facet_with_items_and_sub_items, owner_types: ['Orga'])

    get :index, params: { facet_id: facet.id }

    assert_response :ok

    json = JSON.parse(response.body)
    assert_kind_of Hash, json

    json_items = json['data']
    assert_kind_of Array, json_items
    assert_equal 2, json_items.count

    json_sub_items = json_items[0]['relationships']['sub_items']['data']
    assert_kind_of Array, json_sub_items
    assert_equal 2, json_sub_items.count
  end

  test 'throw 404 error on create with wrong params' do
    post :create, params: { facet_id: 1, title: 'new facet item' }
    assert_response :not_found
  end

  test 'update facet item with new facet and parent' do
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

  test 'throw error if linking owner which is not supported by facet' do
    facet = create(:facet, owner_types: ['Orga'])
    facet_item = create(:facet_item, facet: facet)
    event = create(:event)

    assert_no_difference -> { DataPlugins::Facet::FacetItemOwner.count } do
      post :link_owners, params: { facet_id: facet.id, owner_type: 'events', owner_id: event.id, id: facet_item.id }
      assert_response :unprocessable_entity
      assert response.body.blank?
    end
  end

  test 'not fail if linking multiple owners fails for one owner which type is not supported by facet' do
    facet = create(:facet, owner_types: ['Event'])
    facet_item = create(:facet_item, facet: facet)
    orga = create(:orga)
    event = create(:event)

    assert_difference -> { DataPlugins::Facet::FacetItemOwner.count } do
      post :link_owners, params: {
        facet_id: facet.id, id: facet_item.id,
        owners: [
          { owner_type: 'orgas', owner_id: orga.id },
          { owner_type: 'events', owner_id: event.id }
        ]
      }
      assert_response :created
      assert response.body.blank?

      assert_nil orga.facet_items.first
      assert_equal facet_item, event.facet_items.first
    end
  end

  test 'get linked facet items' do
    facet = create(:facet_with_items, owner_types: ['Orga'])
    facet_item = facet.facet_items.first
    facet_item2 = facet.facet_items.last
    orga = create(:orga)

    facet_item.link_owner(orga)
    facet_item2.link_owner(orga)

    get :get_linked_facet_items, params: { owner_type: 'orgas', owner_id: orga.id }
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal 2, json.count
    assert_equal JSON.parse(facet_item.to_json), json.first
    assert_equal JSON.parse(facet_item2.to_json), json[1]
  end

  test 'link multiple facet items with owner' do
    facet = create(:facet_with_items, owner_types: ['Orga'])
    facet_item = facet.facet_items.first
    facet_item2 = facet.facet_items.last
    orga = create(:orga)

    post :link_facet_items, params: {
      owner_type: 'orgas',
      owner_id: orga.id,
      facet_items: [facet_item.id, facet_item2.id]
    }
    assert_response :created

    assert_equal facet_item, orga.facet_items.first
    assert_equal facet_item2, orga.facet_items.second
  end

  test 'unlink all facet items from owner' do
    facet = create(:facet_with_items, owner_types: ['Orga'])
    facet_item = facet.facet_items.first
    facet_item2 = facet.facet_items.last
    orga = create(:orga)

    facet_item.link_owner(orga)
    facet_item2.link_owner(orga)
    assert_equal facet_item, orga.facet_items.first
    assert_equal facet_item2, orga.facet_items.second

    post :link_facet_items, params: {
      owner_type: 'orgas',
      owner_id: orga.id,
      facet_items: []
    }
    assert_response :created

    assert_nil orga.facet_items.first
    assert_nil orga.facet_items.second
  end

  test 'not fail if linking multiple facet items with owner where one is not allowed' do
    facet = create(:facet_with_items, owner_types: ['Orga'])
    facet_item = facet.facet_items.first
    facet2 = create(:facet_with_items, owner_types: ['Event'])
    facet_item2 = facet2.facet_items.first
    orga = create(:orga)

    post :link_facet_items, params: {
      owner_type: 'orgas',
      owner_id: orga.id,
      facet_items: [facet_item.id, facet_item2.id]
    }
    assert_response :created

    assert_equal facet_item, orga.facet_items.first
    assert_nil orga.facet_items.second
  end

  test 'fail if linking multiple facet items with owner where one does not exist' do
    facet = create(:facet_with_items, owner_types: ['Orga'])
    facet_item = facet.facet_items.first
    orga = create(:orga)

    post :link_facet_items, params: {
      owner_type: 'orgas',
      owner_id: orga.id,
      facet_items: [facet_item.id, 85555555]
    }
    assert_response :unprocessable_entity

    assert_nil orga.facet_items.first
    assert_nil orga.facet_items.second
  end

  private

  def create_root
    create(:facet, owner_types: ['Orga', 'Event', 'Offer'])
  end

  def create_root_with_items
    create(:facet_with_items, owner_types: ['Orga', 'Event', 'Offer'])
  end

  def create_root_with_items_and_sub_items
    create(:facet_with_items_and_sub_items, owner_types: ['Orga', 'Event', 'Offer'])
  end

  def create_item_with_root(facet)
    create(:facet_item, facet: facet)
  end

  def get_root_items(facet)
    facet.facet_items
  end

  def get_owner_items(owner)
    owner.facet_items
  end

  def ownerClass
    DataPlugins::Facet::FacetItemOwner
  end

  def itemClass
    DataPlugins::Facet::FacetItem
  end

  def params(root, params)
    params[:facet_id] = root.id
    params
  end

end
