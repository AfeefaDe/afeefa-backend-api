require 'test_helper'

class DataModules::FeNavigation::V1::FeNavigationItemsControllerTest < ActionController::TestCase

  include ActsAsFacetItemControllerTest

  def create_root
    create(:fe_navigation)
  end

  def create_root_with_items
    create(:fe_navigation_with_items)
  end

  def create_root_with_items_and_sub_items
    create(:fe_navigation_with_items_and_sub_items)
  end

  def create_item_with_root(navigation)
    create(:fe_navigation_item, navigation: navigation)
  end

  def get_root_items(navigation)
    navigation.navigation_items
  end

  def get_owner_items(owner)
    owner.navigation_items
  end

  def ownerClass
    DataModules::FeNavigation::FeNavigationItemOwner
  end

  def itemClass
    DataModules::FeNavigation::FeNavigationItem
  end

  def params(root, params)
    params
  end


  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'link facet items' do
      facet = create(:facet_with_items, owner_types: ['Offer'])
      facet_item = facet.facet_items.first

      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first

      offer = create(:offer)
      facet_item.link_owner(offer)

      assert_difference -> { ownerClass.count } do
        post :link_owners, params: { id: navigation_item.id, owner_type: 'facet_items', owner_id: facet_item.id }
        assert_response :created
        assert response.body.blank?

        assert_equal offer, navigation_item.owners.first
        assert_equal facet_item, navigation_item.facet_items.first
      end
    end

    should 'link multiple owners' do
      facet = create(:facet_with_items, owner_types: ['Offer', 'Event', 'Orga'])
      facet_item = facet.facet_items.first
      facet_item2 = facet.facet_items.last

      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first

      event = create(:event)
      offer = create(:offer)
      facet_item.link_owner(offer)
      facet_item.link_owner(event)

      orga2 = create(:orga_with_random_title)
      facet_item2.link_owner(orga2)

      orga = create(:orga)

      assert_difference -> { ownerClass.count }, 3 do
        post :link_owners, params: {
          id: navigation_item.id,
          owners: [
            { owner_type: 'orgas', owner_id: orga.id },
            { owner_type: 'facet_items', owner_id: facet_item.id },
            { owner_type: 'facet_items', owner_id: facet_item2.id }
          ]
        }
        assert_response :created
        assert response.body.blank?

        assert_same_elements [orga, offer, event, orga2], navigation_item.owners
        assert_same_elements [facet_item, facet_item2], navigation_item.facet_items
      end
    end

    should 'get owners with owners from linked facet items' do
      facet = create(:facet_with_items, owner_types: ['Offer', 'Event', 'Orga'])
      facet_item = facet.facet_items.first
      facet_item2 = facet.facet_items.last

      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first

      event = create(:event)
      offer = create(:offer)
      facet_item.link_owner(offer)
      facet_item.link_owner(event)

      orga2 = create(:orga_with_random_title)
      facet_item2.link_owner(orga2)

      orga = create(:orga)
      navigation_item.link_owner(orga)
      navigation_item.link_owner(facet_item)
      navigation_item.link_owner(facet_item2)

      get :get_linked_owners, params: { id: navigation_item.id }
      assert_response :ok

      json = JSON.parse(response.body)
      assert_equal 4, json.count

      assert_same_elements [
        orga.to_hash.as_json,
        event.to_hash.as_json,
        offer.to_hash.as_json,
        orga2.to_hash.as_json
      ], json
    end

    should 'link multiple facet items with navigation item' do
      facet = create(:facet_with_items)
      facet_item = facet.facet_items.first
      facet_item2 = facet.facet_items.last

      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first

      post :link_facet_items, params: {
        id: navigation_item.id,
        facet_items: [facet_item.id, facet_item2.id]
      }
      assert_response :created

      assert_equal facet_item, navigation_item.facet_items.first
      assert_equal facet_item2, navigation_item.facet_items.second
    end

    should 'unlink all facet items from navigation item' do
      facet = create(:facet_with_items)
      facet_item = facet.facet_items.first
      facet_item2 = facet.facet_items.last

      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first

      navigation_item.link_owner(facet_item)
      navigation_item.link_owner(facet_item2)
      assert_equal facet_item, navigation_item.facet_items.first
      assert_equal facet_item2, navigation_item.facet_items.second

      post :link_facet_items, params: {
        id: navigation_item.id,
        facet_items: []
      }
      assert_response :created

      assert_nil navigation_item.facet_items.first
      assert_nil navigation_item.facet_items.second
    end

    should 'fail if linking multiple facet items with navigation item where one does not exist' do
      facet = create(:facet_with_items)
      facet_item = facet.facet_items.first

      navigation = create(:fe_navigation_with_items)
      navigation_item = navigation.navigation_items.first

      post :link_facet_items, params: {
        id: navigation_item.id,
        facet_items: [facet_item.id, 85555555]
      }
      assert_response :unprocessable_entity

      assert_nil navigation_item.facet_items.first
      assert_nil navigation_item.facet_items.second
    end

  end
end
