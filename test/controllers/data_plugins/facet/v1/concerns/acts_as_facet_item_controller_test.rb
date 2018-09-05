module ActsAsFacetItemControllerTest
  extend ActiveSupport::Concern

  included do

    context 'as authorized user' do
      setup do
        stub_current_user
      end

      should 'get single item' do
        root = create_root_with_items_and_sub_items
        item = get_root_items(root).first

        get :show, params: params(root, { id: item.id })

        assert_response :ok

        json = JSON.parse(response.body)
        assert_equal JSON.parse(item.to_json), json['data']
      end

      should 'set the right parent_id' do
        root = create_root_with_items_and_sub_items
        parent = get_root_items(root).select { |item| item.sub_items.count > 0 }.first
        sub_item = parent.sub_items.first
        sub_item2 = parent.sub_items.last

        get :show, params: params(root, { id: parent.id })

        json = JSON.parse(response.body)['data']

        assert_nil json['attributes']['parent_id']

        json_sub_items = json['relationships']['sub_items']['data']
        assert_kind_of Array, json_sub_items
        assert_equal 2, json_sub_items.count

        assert_equal parent.id, json_sub_items[0]['attributes']['parent_id']
        assert_equal parent.id, json_sub_items[1]['attributes']['parent_id']
      end

      should 'get linked owners' do
        root = create_root_with_items
        item = get_root_items(root).first

        orga = create(:orga)
        event = create(:event)
        offer = create(:offer)

        item.link_owner(orga)
        item.link_owner(event)
        item.link_owner(offer)

        get :get_linked_owners, params: params(root, { id: item.id })
        assert_response :ok

        json = JSON.parse(response.body)

        assert_equal 3, json.count

        assert_same_elements [
          orga.to_hash.as_json, # converts dates to json
          event.to_hash.as_json,
          offer.to_hash.as_json
        ], json
      end

      should 'not deliver owners multiple times if also added to sub items' do
        root = create_root_with_items_and_sub_items

        parent = get_root_items(root).select { |item| item.parent == nil }.first
        sub_item = parent.sub_items.first

        orga = create(:orga)
        sub_item.link_owner(orga)

        assert_same_elements [parent, sub_item], get_owner_items(orga)

        get :get_linked_owners, params: params(root, { id: parent.id })
        assert_response :ok

        json = JSON.parse(response.body)
        assert_equal 1, json.count

        assert_equal orga.to_hash.as_json, json.first
      end

      should 'create item' do
        root = create_root
        assert_difference -> { itemClass.count } do
          post :create, params: params(root, { title: 'new item' })
          assert_response :created
        end
        json = JSON.parse(response.body)
        item = itemClass.last
        assert_equal JSON.parse(item.to_json), json
      end

      should 'update item' do
        root = create_root_with_items
        item = get_root_items(root).first

        assert_no_difference -> { itemClass.count } do
          patch :update, params: params(root, { id: item.id, title: 'changed item' })
          assert_response :ok
        end

        json = JSON.parse(response.body)
        item.reload
        assert_equal 'changed item', item.title
        assert_equal JSON.parse(item.to_json), json
      end

      should 'update item with new parent' do
        root = create_root_with_items_and_sub_items
        parent = get_root_items(root).select { |item| item.sub_items.count > 0 }.first
        sub_item = parent.sub_items.first
        parent2 = get_root_items(root).select { |item| item.sub_items.count > 0 }.last

        assert_no_difference -> { itemClass.count } do
          patch :update, params: params(root, { id: sub_item.id, parent_id: parent2.id, title: 'changed item' })
          assert_response :ok
        end

        json = JSON.parse(response.body)
        sub_item.reload
        assert_equal sub_item.parent_id, parent2.id
        assert_equal JSON.parse(sub_item.to_json), json
      end

      should 'throw error on update item with wrong params' do
        root = create_root_with_items
        item = get_root_items(root).first

        patch :update, params: params(root, { id: item.id, parent_id: 123, title: 'changed item' })
        assert_response :unprocessable_entity
      end

      should 'remove item' do
        root = create_root_with_items_and_sub_items
        parent = get_root_items(root).select { |item| item.sub_items.count > 0 }.first
        sub_item = parent.sub_items.first

        assert_difference -> { itemClass.count }, -1 do
          delete :destroy, params: params(root, { id: sub_item.id })
          assert_response 200
          assert response.body.blank?
        end

        get :show, params: params(root, { id: parent.id })
        json = JSON.parse(response.body)
        assert_equal 1, json['data']['relationships']['sub_items'].count
        assert_equal JSON.parse(parent.to_json), json['data']
      end

      should 'link owner with item' do
        root = create_root_with_items
        item = get_root_items(root).first
        orga = create(:orga)

        assert_difference -> { ownerClass.count } do
          post :link_owners, params: params(root, { id: item.id, owner_type: 'orgas', owner_id: orga.id })
          assert_response :created
          assert response.body.blank?

          assert_equal orga, item.owners.first
        end
      end

      should 'throw error on link item again' do
        root = create_root_with_items
        item = get_root_items(root).first
        orga = create(:orga)

        item.link_owner(orga)

        assert_no_difference -> { ownerClass.count } do
          post :link_owners, params: params(root, { owner_type: 'orgas', owner_id: orga.id, id: item.id })
          assert_response :unprocessable_entity
          assert response.body.blank?
        end
      end

      should 'link owners of multiple types with item' do
        root = create_root_with_items
        item = get_root_items(root).first
        orga = create(:orga)
        event = create(:event)
        offer = create(:offer)

        assert_difference -> { ownerClass.count } do
          post :link_owners, params: params(root, { id: item.id, owner_type: 'orgas', owner_id: orga.id })
          assert_response :created
        end

        assert_difference -> { ownerClass.count } do
          post :link_owners, params: params(root, { id: item.id, owner_type: 'events', owner_id: event.id })
          assert_response :created
        end

        assert_difference -> { ownerClass.count } do
          post :link_owners, params: params(root, { id: item.id, owner_type: 'offers', owner_id: offer.id })
          assert_response :created
        end

        assert_same_elements [orga, event, offer], item.owners
      end

      should 'unlink owner from item' do
        root = create_root_with_items
        item = get_root_items(root).first
        orga = create(:orga)
        item.link_owner(orga)

        assert_difference -> { ownerClass.count }, -1 do
          delete :unlink_owners, params: params(root, { id: item.id, owner_type: 'orgas', owner_id: orga.id })
          assert_response :ok
          assert response.body.blank?

          assert_equal [], item.owners
        end
      end

      should 'throw error on unlink facet item again' do
        root = create_root_with_items
        item = get_root_items(root).first
        orga = create(:orga)

        assert_no_difference -> { ownerClass.count } do
          delete :unlink_owners, params: params(root, { id: item.id, owner_type: 'orgas', owner_id: orga.id })
          assert_response :not_found
          assert response.body.blank?
        end
      end

      should 'link multiple owners with facet item' do
        root = create_root
        item = create_item_with_root(root)
        orga = create(:orga)
        orga2 = create(:orga, title: 'another orga')

        assert_difference -> { ownerClass.count }, 2 do
          post :link_owners, params: params(root, {
            id: item.id,
            owners: [
              { owner_type: 'orgas', owner_id: orga.id },
              { owner_type: 'orgas', owner_id: orga2.id }
            ]
          })
          assert_response :created
          assert response.body.blank?

          assert_equal item, get_owner_items(orga).first
          assert_equal item, get_owner_items(orga2).first
        end
      end

      should 'call item.link_owner on link multiple owners' do
        root = create_root_with_items
        item = get_root_items(root).first

        orga = create(:orga)
        orga2 = create(:orga, title: 'another orga')

        itemClass.any_instance.expects(:link_owner).with(orga)
        itemClass.any_instance.expects(:link_owner).with(orga2)

        post :link_owners, params:  params(root, {
          id: item.id,
          owners: [
            { owner_type: 'orgas', owner_id: orga.id },
            { owner_type: 'orgas', owner_id: orga2.id }
          ]
        })
      end

      should 'link owners of multiple types with facet item' do
        root = create_root
        item = create_item_with_root(root)
        orga = create(:orga)
        orga2 = create(:orga, title: 'another orga')
        event = create(:event, orga: orga2)
        offer = create(:offer, actors: [orga.id])

        assert_difference -> { ownerClass.count }, 4 do
          post :link_owners, params: params(root, {
            id: item.id,
            owners: [
              { owner_type: 'orgas', owner_id: orga.id },
              { owner_type: 'orgas', owner_id: orga2.id },
              { owner_type: 'events', owner_id: event.id },
              { owner_type: 'offers', owner_id: offer.id }
            ]
          })
          assert_response :created
          assert response.body.blank?

          assert_equal item, get_owner_items(orga).first
          assert_equal item, get_owner_items(orga2).first
          assert_equal item, get_owner_items(event).first
          assert_equal item, get_owner_items(offer).first
        end
      end

      should 'not fail if linking multiple owners fails for one owner with already existing association' do
        root = create_root
        item = create_item_with_root(root)
        orga = create(:orga)
        orga2 = create(:orga, title: 'another orga')

        item.link_owner(orga)

        assert_difference -> { ownerClass.count }, 1 do
          post :link_owners, params: params(root, {
            id: item.id,
            owners: [
              { owner_type: 'orgas', owner_id: orga.id },
              { owner_type: 'orgas', owner_id: orga2.id }
            ]
          })
          assert_response :created
          assert response.body.blank?

          assert_equal item, get_owner_items(orga).first
          assert_equal item, get_owner_items(orga2).first
        end
      end

      should 'throw error if linking multiple owners fails for one owner which does not exist' do
        root = create_root
        item = create_item_with_root(root)
        orga = create(:orga)

        assert_no_difference -> { ownerClass.count } do
          post :link_owners, params: params(root, {
            id: item.id,
            owners: [
              { owner_type: 'orgas', owner_id: orga.id },
              { owner_type: 'test', owner_id: 473 }
            ]
          })
          assert_response :unprocessable_entity
          assert response.body.blank?

          assert_nil get_owner_items(orga).first
        end
      end

      should 'throw error if linking multiple owners fails for all owners' do
        root = create_root
        item = create_item_with_root(root)
        orga = create(:orga)
        item.link_owner(orga)

        assert_no_difference -> { ownerClass.count } do
          post :link_owners, params: params(root, {
            id: item.id,
            owners: [
              { owner_type: 'orgas', owner_id: orga.id } # already linked
            ]
          })
          assert_response :unprocessable_entity
          assert response.body.blank?
        end
      end

      should 'unlink multiple owners from facet item' do
        root = create_root
        item = create_item_with_root(root)
        orga = create(:orga)
        orga2 = create(:orga, title: 'another orga')

        item.link_owner(orga)
        item.link_owner(orga2)

        assert_difference -> { ownerClass.count }, -2 do
          post :unlink_owners, params: params(root, {
            id: item.id,
            owners: [
              { owner_type: 'orgas', owner_id: orga.id },
              { owner_type: 'orgas', owner_id: orga2.id }
            ]
          })
          assert_response :ok
          assert response.body.blank?

          assert_nil get_owner_items(orga).first
          assert_nil get_owner_items(orga2).first
        end
      end

      should 'call item.unlink_owner on link multiple owners' do
        root = create_root_with_items
        item = get_root_items(root).first

        orga = create(:orga)
        orga2 = create(:orga, title: 'another orga')

        item.link_owner(orga)
        item.link_owner(orga2)

        itemClass.any_instance.expects(:unlink_owner).with(orga)
        itemClass.any_instance.expects(:unlink_owner).with(orga2)

        post :unlink_owners, params: params(root, {
          id: item.id,
          owners: [
            { owner_type: 'orgas', owner_id: orga.id },
            { owner_type: 'orgas', owner_id: orga2.id }
          ]
        })
      end

      should 'not fail if unlinking multiple owners fails for one owner without existing association' do
        root = create_root_with_items
        item = get_root_items(root).first

        orga = create(:orga)
        orga2 = create(:orga, title: 'another orga')
        item.link_owner(orga)

        assert_difference -> { ownerClass.count }, -1 do
          post :unlink_owners, params: params(root, {
            id: item.id,
            owners: [
              { owner_type: 'orgas', owner_id: orga.id },
              { owner_type: 'orgas', owner_id: orga2.id }
            ]
          })
          assert_response :ok
          assert response.body.blank?

          assert_nil get_owner_items(orga).first
          assert_nil get_owner_items(orga2).first
        end
      end

      should 'throw error if unlinking multiple owners fails for one nonexisting owner' do
        root = create_root_with_items
        item = get_root_items(root).first

        orga = create(:orga)
        item.link_owner(orga)

        assert_no_difference -> { ownerClass.count } do
          post :unlink_owners, params: params(root, {
            id: item.id,
            owners: [
              { owner_type: 'orgas', owner_id: orga.id },
              { owner_type: 'test', owner_id: 473 }
            ]
          })
          assert_response :unprocessable_entity
          assert response.body.blank?
        end
      end

      should 'throw error if unlinking multiple owners fails for all owners' do
        root = create_root_with_items
        item = get_root_items(root).first

        orga = create(:orga)

        assert_no_difference -> { ownerClass.count } do
          post :unlink_owners, params: params(root, {
            id: item.id,
            owners: [
              { owner_type: 'orgas', owner_id: orga.id }
            ]
          })
          assert_response :unprocessable_entity
          assert response.body.blank?
        end
      end

    end

  end

end