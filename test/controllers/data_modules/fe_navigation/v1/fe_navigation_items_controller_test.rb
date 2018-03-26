require 'test_helper'

class DataModules::FENavigation::V1::FENavigationItemsControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get navigation items' do
      navigation = create(:fe_navigation_with_items_and_sub_items)

      get :index

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

    should 'get single navigation item' do
      navigation = create(:fe_navigation_with_items_and_sub_items)
      navigation_item = navigation.navigation_items.first

      get :show, params: { id: navigation_item.id }

      assert_response :ok

      json = JSON.parse(response.body)
      assert_equal JSON.parse(navigation_item.to_json), json['data']
    end

    should 'create navigation item' do
      navigation = create(:fe_navigation)
      assert_difference -> { DataModules::FENavigation::FENavigationItem.count } do
        post :create, params: { title: 'new navigation item' }
        assert_response :created
      end
      json = JSON.parse(response.body)
      navigation_item = DataModules::FENavigation::FENavigationItem.last
      assert_equal JSON.parse(navigation_item.to_json), json
    end

    should 'update navigation item' do
      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first

      assert_no_difference -> { DataModules::FENavigation::FENavigationItem.count } do
        patch :update, params: { id: navigation_item.id, title: 'changed navigation item' }
        assert_response :ok
      end

      json = JSON.parse(response.body)
      navigation_item.reload
      assert_equal 'changed navigation item', navigation_item.title
      assert_equal JSON.parse(navigation_item.to_json), json
    end

    should 'update navigation item with new parent' do
      navigation = create(:fe_navigation_with_items_and_sub_items)
      parent = navigation.navigation_items.select { |item| item.sub_items.count > 0 }.first
      sub_item = parent.sub_items.first
      parent2 = navigation.navigation_items.select { |item| item.sub_items.count > 0 }.last

      assert_no_difference -> { DataModules::FENavigation::FENavigationItem.count } do
        patch :update, params: { id: sub_item.id, parent_id: parent2.id, title: 'changed navigation item' }
        assert_response :ok
      end

      json = JSON.parse(response.body)
      sub_item.reload
      assert_equal sub_item.parent_id, parent2.id
      assert_equal JSON.parse(sub_item.to_json), json
    end

    should 'throw error on update navigation item with wrong params' do
      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first

      patch :update, params: { id: navigation_item.id, parent_id: 123, title: 'changed navigation item' }
      assert_response :unprocessable_entity
    end

    should 'remove navigation item' do
      navigation = create(:fe_navigation_with_items_and_sub_items)
      parent = navigation.navigation_items.select { |item| item.sub_items.count > 0 }.first
      sub_item = parent.sub_items.first

      assert_difference -> { DataModules::FENavigation::FENavigationItem.count }, -1 do
        delete :destroy, params: { id: sub_item.id }
        assert_response 200
        assert response.body.blank?
      end

      get :show, params: { id: parent.id }
      json = JSON.parse(response.body)
      assert_equal 1, json['data']['relationships']['sub_items'].count
      assert_equal JSON.parse(parent.to_json), json['data']
    end

    should 'link owner with navigation item' do
      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first
      orga = create(:orga)

      assert_difference -> { DataModules::FENavigation::FENavigationItemOwner.count } do
        post :link_owner, params: { id: navigation_item.id, owner_type: 'orgas', owner_id: orga.id }
        assert_response :created
        assert response.body.blank?

        assert_equal orga, navigation_item.owners.first
      end
    end

    should 'link owners of multiple types with navigation item' do
      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first
      orga = create(:orga)
      event = create(:event)
      offer = create(:offer)

      assert_difference -> { DataModules::FENavigation::FENavigationItemOwner.count } do
        post :link_owner, params: { id: navigation_item.id, owner_type: 'orgas', owner_id: orga.id }
        assert_response :created
      end

      assert_difference -> { DataModules::FENavigation::FENavigationItemOwner.count } do
        post :link_owner, params: { id: navigation_item.id, owner_type: 'events', owner_id: event.id }
        assert_response :created
      end

      assert_difference -> { DataModules::FENavigation::FENavigationItemOwner.count } do
        post :link_owner, params: { id: navigation_item.id, owner_type: 'offers', owner_id: offer.id }
        assert_response :created
      end

      assert_same_elements [orga, event, offer], navigation_item.owners
    end

    should 'get linked owners' do
      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first

      orga = create(:orga)
      event = create(:event)
      offer = create(:offer)

      navigation_item.link_owner(orga)
      navigation_item.link_owner(event)
      navigation_item.link_owner(offer)

      get :get_linked_owners, params: { id: navigation_item.id }
      assert_response :ok

      json = JSON.parse(response.body)
      assert_equal 3, json.count

      assert_same_elements [
        orga.to_hash(attributes: [:title], relationships: nil).deep_stringify_keys,
        event.to_hash(attributes: [:title], relationships: nil).deep_stringify_keys,
        offer.to_hash(attributes: [:title], relationships: nil).deep_stringify_keys
      ], json
    end

    should 'unlink owner from navigation item' do
      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first
      orga = create(:orga)
      navigation_item.link_owner(orga)

      assert_difference -> { DataModules::FENavigation::FENavigationItemOwner.count }, -1 do
        delete :unlink_owner, params: { id: navigation_item.id, owner_type: 'orgas', owner_id: orga.id }
        assert_response :ok
        assert response.body.blank?

        assert_equal [], navigation_item.owners
      end
    end

  end

end
