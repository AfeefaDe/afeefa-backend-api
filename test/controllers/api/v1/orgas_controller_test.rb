require 'test_helper'

class Api::V1::OrgasControllerTest < ActionController::TestCase
  include ActsAsHasActorRelationsControllerTest

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get index' do
      # useful sample data
      orga = create(:orga)
      Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: AnnotationCategory.first)
      orga.annotations.last
      orga.sub_orgas.create(attributes_for(:another_orga, parent_orga: orga))

      get :index, params: { include: 'annotations,category,sub_category' }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Orga.count, json['data'].size
      assert_equal Orga.last.
        to_hash(attributes: Orga.lazy_attributes_for_json, relationships: Orga.lazy_relations_for_json).
        deep_stringify_keys, json['data'].last
      assert_equal Orga.last.active, json['data'].last['attributes']['active']

      assert_not json['data'].last['attributes'].key?('support_wanted_detail')
      assert_not json['data'].last['relationships'].key?('resources')
    end

    should 'deliver initiators with different detail granularity' do
      orga = create(:orga_with_initiator)

      get :index
      json = JSON.parse(response.body)['data'][0]

      assert_nil json['relationships']['project_initiators']

      get :index, params: { ids: [orga.id] }
      json = JSON.parse(response.body)['data'][0]

      assert_equal 1, json['relationships']['project_initiators']['data'][0]['attributes'].count
      assert_nil json['relationships']['project_initiators']['data'][0]['attributes']['count_projects']

      get :show, params: { id: orga.id }
      json = JSON.parse(response.body)['data']

      assert_operator 1, :<, json['relationships']['project_initiators']['data'][0]['attributes'].count
      assert_equal 1, json['relationships']['project_initiators']['data'][0]['attributes']['count_projects']
    end

    should 'deliver different attributes and relations when show or index' do
      orga = create(:orga)

      get :index
      json = JSON.parse(response.body)['data'][0]

      attributes = [
        'title',
        'created_at',
        'updated_at',
        'active'
      ]

      relationships = [
        'facet_items',
        'navigation_items'
      ]

      assert_same_elements attributes, json['attributes'].keys
      assert_same_elements relationships, json['relationships'].keys

      get :index, params: { ids: [orga.id] }
      json = JSON.parse(response.body)['data'][0]

      attributes = [
        'orga_type_id',
        'title',
        'created_at',
        'updated_at',
        'state_changed_at',
        'active',
        'count_upcoming_events',
        'count_past_events',
        'count_resource_items',
        'count_projects',
        'count_network_members',
        'count_offers'
      ]

      relationships = [
        'project_initiators',
        'annotations',
        'facet_items',
        'navigation_items',
        'creator',
        'last_editor'
      ]

      assert_same_elements attributes, json['attributes'].keys
      assert_same_elements relationships, json['relationships'].keys

      get :show, params: { id: orga.id }
      json = JSON.parse(response.body)['data']

      attributes = [
        'orga_type_id',
        'title',
        'created_at',
        'updated_at',
        'state_changed_at',
        'active',
        'count_upcoming_events',
        'count_past_events',
        'count_resource_items',
        'count_projects',
        'count_network_members',
        'count_offers',
        'description',
        'short_description',
        'media_url',
        'media_type',
        'support_wanted',
        'support_wanted_detail',
        'tags',
        'certified_sfr',
        'inheritance',
        'facebook_id',
        'contact_spec'
      ]

      relationships = [
        'project_initiators',
        'annotations',
        'facet_items',
        'navigation_items',
        'creator',
        'last_editor',
        'resource_items',
        'contacts',
        'offers',
        'projects',
        'networks',
        'network_members',
        'partners'
      ]

      assert_same_elements attributes, json['attributes'].keys
      assert_same_elements relationships, json['relationships'].keys
    end

    should 'get index only data of area of user' do
      user = @controller.current_api_v1_user

      # useful sample data
      orga = create(:orga, area: user.area + ' is different', parent: nil)
      assert_not_equal orga.area, user.area
      Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: AnnotationCategory.first)
      orga.annotations.last
      orga.sub_orgas.create(attributes_for(:another_orga, parent_orga: orga, area: 'foo'))

      get :index, params: { include: 'annotations,category,sub_category' }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 0, json['data'].size

      assert orga.update(area: user.area)

      get :index, params: { include: 'annotations,category,sub_category' }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Orga.by_area(user.area).count, json['data'].size
      orga_from_db = Orga.by_area(user.area).last
      assert_equal orga_from_db.
        to_hash(attributes: Orga.lazy_attributes_for_json, relationships: Orga.lazy_relations_for_json).
        deep_stringify_keys, json['data'].last
      assert_equal orga_from_db.active, json['data'].last['attributes']['active']
    end

    should 'not get show root_orga' do
      not_existing_id = 999
      assert Orga.where(id: not_existing_id).blank?
      get :show, params: { id: not_existing_id }
      assert_response :not_found, response.body
    end

    should 'I want to create a new orga' do
      params = parse_json_file do |payload|
        payload.gsub!('<orga_type_id>', OrgaType.default_orga_type_id.to_s)
      end
      params['data']['attributes'].merge!('active' => true)

      assert_difference 'Orga.count' do
        post :create, params: params
        assert_response :created, response.body
      end
      json = JSON.parse(response.body)
      assert_equal StateMachine::ACTIVE.to_s, Orga.last.state
      assert_equal true, json['data']['attributes']['active']

      # Then we could deliver the mapping there
      %w(contacts).each do |relation|
        assert json['data']['relationships'][relation].key?('data'), 'No element for relation #{relation} found.'
        to_check = json['data']['relationships'][relation]['data'].first
        assert_equal relation, to_check['type'] if to_check
      end

      user = @controller.current_api_v1_user
      assert_equal user.area, Orga.last.area
      assert_equal user.id, Orga.last.creator_id
      assert_equal user.id, Orga.last.last_editor_id
      assert_equal user.id.to_s, json['data']['relationships']['creator']['data']['id']
    end

    should 'not allow to create orga with existing title' do
      orga = create(:orga, title: 'test')

      exception = assert_raises(ActiveRecord::RecordInvalid) {
        orga2 = create(:orga, title: 'test')
      }
      assert_match 'Titel ist bereits vergeben', exception.message

      # offer event are allowed
      assert create(:offer, title: 'test')
      assert create(:event, title: 'test')
    end

    should 'allow to create orga with existing title in other area' do
      orga = create(:orga, title: 'test', area: 'area')
      orga2 = create(:orga, title: 'test', area: 'area2')

      assert_equal orga.title, orga2.title
    end

    context 'with given orga' do
      setup do
        @orga = create(:orga)
      end

      should 'get show' do
        get :show, params: { id: @orga.id }
        assert_response :ok, response.body
        json = JSON.parse(response.body)
        assert_kind_of Hash, json['data']
        assert_equal false, json['data']['attributes']['active']
        assert_equal Orga.attribute_whitelist_for_json.sort, json['data']['attributes'].symbolize_keys.keys.sort
        assert_equal Orga.relation_whitelist_for_json.sort, json['data']['relationships'].symbolize_keys.keys.sort
      end

      should 'get show with resources' do
        resource = ResourceItem.create!(title: 'test resource', description: 'demo test', orga: @orga)

        get :show, params: { id: @orga.id }
        assert_response :ok, response.body
        json = JSON.parse(response.body)
        assert_kind_of Hash, json['data']
        assert_equal false, json['data']['attributes']['active']
        assert_equal Orga.attribute_whitelist_for_json.sort, json['data']['attributes'].symbolize_keys.keys.sort
        assert_equal Orga.relation_whitelist_for_json.sort, json['data']['relationships'].symbolize_keys.keys.sort
      end

      should 'update should fail for invalid' do
        assert_no_difference 'Orga.count' do
          assert_no_difference 'AnnotationCategory.count' do
            assert_no_difference 'ContactInfo.count' do
              assert_no_difference 'Location.count' do
                post :create, params: {
                  data: {
                    type: 'orgas',
                    attributes: {
                    },
                    relationships: {
                    }
                  }
                }
                assert_response :unprocessable_entity
                json = JSON.parse(response.body)
                assert_equal(
                  [
                    'Titel - fehlt',
                    'Kurzbeschreibung - fehlt'
                  ],
                  json['errors'].map { |x| x['detail'] }
                )
              end
            end
          end
        end
      end

      should 'update orga with nested attributes' do
        creator = create(:user)
        orga = create(:orga, title: 'foobar', creator_id: creator.id)
        assert_difference 'ResourceItem.count' do
          ResourceItem.create!(title: 'ganz wichtige Ressource', orga: orga)
        end
        resource = orga.reload.resource_items.last

        assert_no_difference 'Orga.count' do
          assert_no_difference 'ResourceItem.count' do
            post :update,
              params: {
                id: orga.id,
              }.merge(
                parse_json_file(
                  file: 'update_orga_with_nested_models.json'
                ) do |payload|
                  payload.gsub!('<id>', orga.id.to_s)
                  payload.gsub!('<resource_id_1>', resource.id.to_s)
                end
              )
            assert_response :ok, response.body
          end
        end
        assert_equal 'Ein Test 3', Orga.last.title
        assert_equal Orga.root_orga.id, Orga.last.parent_orga_id
        assert_equal 1, Orga.last.resource_items.count
        assert_equal resource, Orga.last.resource_items.first
        assert_equal 'foo-bar', resource.reload.title

        user = @controller.current_api_v1_user
        assert_not_equal creator.id, user.id
        assert_equal user.area, Orga.last.area
        assert_equal creator.id, Orga.last.creator_id # kept
        assert_equal user.id, Orga.last.last_editor_id

        json = JSON.parse(response.body)
        assert_equal creator.id.to_s, json['data']['relationships']['creator']['data']['id']
        assert_equal user.id.to_s, json['data']['relationships']['last_editor']['data']['id']
      end

      should 'deactivate an inactive invalid orga' do
        orga = create(:orga, title: 'foobar')
        orga.title = nil
        assert_not orga.valid?
        assert orga.save(validate: false)

        assert_no_difference 'Orga.count' do
          assert_no_difference 'ContactInfo.count' do
            assert_no_difference 'Location.count' do
              post :update,
                params: {
                  id: orga.id,
                }.merge(
                  parse_json_file(
                    file: 'deactivate_orga.json'
                  ) do |payload|
                    payload.gsub!('<id>', orga.id.to_s)
                  end
                )
              assert_response :ok, response.body
            end
          end
        end
        assert orga.reload.inactive?
        assert orga.title.blank?
      end

      should 'deactivate an active invalid orga' do
        orga = create(:orga, title: 'foobar')
        orga.title = nil
        orga.state = StateMachine::ACTIVE
        assert_not orga.valid?
        assert orga.save(validate: false)
        assert orga.reload.active?

        assert_no_difference 'Orga.count' do
          assert_no_difference 'ContactInfo.count' do
            assert_no_difference 'Location.count' do
              post :update,
                params: {
                  id: orga.id,
                }.merge(
                  parse_json_file(
                    file: 'deactivate_orga.json'
                  ) do |payload|
                    payload.gsub!('<id>', orga.id.to_s)
                  end
                )
              assert_response :ok, response.body
           end
          end
        end
        assert orga.reload.inactive?
        assert orga.title.blank?
      end

      should 'destroy orga destroys contacts and locations' do
        assert @orga.locations.any?
        assert @orga.contacts.any?
        assert_equal @orga.locations.first, @orga.contacts.first.location

        assert_difference 'Orga.count', -1 do
          assert_difference 'Orga.undeleted.count', -1 do
            assert_difference -> { DataPlugins::Contact::Contact.count }, -1 do
              assert_difference -> { DataPlugins::Location::Location.count }, -1 do
                assert_no_difference 'AnnotationCategory.count' do
                  delete :destroy,
                    params: {
                      id: @orga.id,
                    }
                  assert_response :no_content, response.body
                end
              end
            end
          end
        end
      end

      should 'destroy orga moves linked contacts and locations to root orga' do
        assert @orga.locations.any?
        assert @orga.contacts.any?
        assert_equal @orga.locations.first, @orga.contacts.first.location

        linked_contact = @orga.linked_contact # will be moved to root
        linked_location = @orga.linked_contact.location # will be moved to root

        orga2 = create(:orga)
        orga2.linked_contact = linked_contact
        orga2.save!

        orga2.linked_contact.location = linked_location
        orga2.linked_contact.save!

        orga3 = create(:orga)
        orga3.linked_contact.location = linked_location
        orga3.linked_contact.save!

        assert orga2.linked_contact = linked_contact
        assert orga2.linked_contact.location = linked_location
        assert orga3.linked_contact.location = linked_location

        assert_equal [@orga, orga2], linked_contact.linking_actors
        assert_equal [@orga, orga2, orga3], linked_location.linking_actors
        assert_equal [@orga.linked_contact, orga3.linked_contact], linked_location.linking_contacts

        assert Orga.root_orga.contacts.blank?
        assert Orga.root_orga.locations.blank?

        assert_difference 'Orga.count', -1 do
          assert_difference 'Orga.undeleted.count', -1 do
            assert_difference 'Orga.root_orga.contacts.count' do
              assert_difference 'Orga.root_orga.locations.count' do
                assert_no_difference -> { DataPlugins::Contact::Contact.count } do
                  assert_no_difference -> { DataPlugins::Location::Location.count } do
                    delete :destroy,
                      params: {
                        id: @orga.id,
                      }
                    assert_response :no_content, response.body
                  end
                end
              end
            end
          end
        end

        assert_equal linked_contact, Orga.root_orga.contacts.first
        assert_equal linked_location, Orga.root_orga.locations.first
      end

      should 'create new orga with parent relation and inheritance' do
        params = parse_json_file file: 'create_orga_with_parent.json' do |payload|
          payload.gsub!('<orga_type_id>', OrgaType.default_orga_type_id.to_s)
          payload.gsub!('<parent_orga_id>', @orga.id.to_s)
        end

        assert_not_nil params['data']['attributes']['inheritance']
        inh = params['data']['attributes']['inheritance']

        assert_difference 'Orga.count' do
          post :create, params: params
          assert_response :created, response.body
        end

        response_json = JSON.parse(response.body)
        new_orga_id = response_json['data']['id']

        assert_equal Orga.find(new_orga_id).parent_orga, @orga

        #todo: ticket #276 somehow in create methode parent_orga is set to 1 (ROOT_ORGA) so inheritance gets unset, but WHY!!! #secondsave
        assert_equal inh, response_json['data']['attributes']['inheritance']
        assert_not_nil response_json['data']['attributes']['inheritance']
      end

      should 'create new orga with resources' do
        params = parse_json_file file: 'create_orga_with_nested_models.json' do |payload|
          payload.gsub!('<orga_type_id>', OrgaType.default_orga_type_id.to_s)
        end

        assert_difference 'Orga.count' do
          assert_difference 'ResourceItem.count', 2 do
            post :create, params: params
            assert_response :created, response.body
          end
        end

        response_json = JSON.parse(response.body)
        new_orga_id = response_json['data']['id']

        resources = ResourceItem.order(id: :desc)[0..1]
        resources.each do |resource|
          assert_equal new_orga_id.to_s, resource.orga_id.to_s
        end
      end
    end
  end
end
