require 'test_helper'

class Api::V1::EventsControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get index' do
      user = create(:user)
      orga = create(:orga)
      event = create(:event, title: 'Hackathon', description: 'Mate fuer alle!', creator: user, orga: orga)

      get :index
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Event.count, json['data'].size
      assert_equal Event.last.serialize_lazy.as_json,
        json['data'].last

      assert !json['data'].last['attributes'].key?('support_wanted_detail')
      assert !json['data'].last['attributes'].key?('state_changed_at')
      assert json['data'].last['attributes'].key?('updated_at')

      get :index, params: { ids: [event.id] }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Event.count, json['data'].size
      assert_equal Event.last.to_hash.deep_stringify_keys, json['data'].last

      assert !json['data'].last['attributes'].key?('support_wanted_detail')
      assert json['data'].last['attributes'].key?('state_changed_at')
      assert json['data'].last['attributes'].key?('updated_at')
    end

    should 'get index only data of area of user' do
      user = @controller.current_api_v1_user

      dummy_user = create(:user)
      orga = create(:orga)
      event =
        create(:event,
          title: 'Hackathon', description: 'Mate fuer alle!', creator: dummy_user, orga: orga,
          area: user.area + ' is different')

      get :index, params: { include: 'annotations,category,sub_category' }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 0, json['data'].size

      assert event.update(area: user.area)

      get :index, params: { include: 'annotations,category,sub_category' }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Event.by_area(user.area).count, json['data'].size
      event_from_db = Event.by_area(user.area).last
      assert_equal event_from_db.serialize_lazy.as_json,
        json['data'].last
      assert_equal event_from_db.active, json['data'].last['attributes']['active']
    end

    should 'get title filtered list for events' do
      user = create(:user)
      orga = create(:orga)
      event0 = create(:event, title: 'Hackathon', description: 'Mate fuer alle!', creator: user, orga: orga)
      event1 = create(:event, title: 'Montagscafe', description: 'Kaffee und so im Schauspielhaus',
        creator: user, orga: orga)
      event2 = create(:event, title: 'Joggen im Garten', description: 'Gemeinsames Laufengehen im Grossen Garten',
        creator: user, orga: orga)

      get :index, params: { filter: { title: 'Garten' } }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 1, json['data'].size
    end

    should 'show legacy events without date_start in past events' do
      user = create(:user)
      orga = create(:orga)

      event0 = create(:event, title: 'Hackathon', description: 'Mate fuer alle!',
        creator: user, orga: orga, date_start: 1.day.ago)

      get :index, params: { filter: { date: 'past' } }
      json = JSON.parse(response.body)
      assert_equal event0.id.to_s, json['data'][0]['id']

      event0.date_start = nil
      event0.save!(validate: false)
      event0.reload
      assert_nil event0.date_start

      get :index, params: { filter: { date: 'past' } }
      json = JSON.parse(response.body)
      assert_equal event0.id.to_s, json['data'][0]['id']
    end

    should 'get events filtered for start and end' do
      user = create(:user)
      orga = create(:orga)

      # starts today morning 00:00
      event0 = create(:event, title: 'Hackathon', description: 'Mate fuer alle!',
        creator: user, orga: orga, date_start: Time.now.in_time_zone(Time.zone).beginning_of_day)

      # starts in 10 minutes
      event1 = create(:event, title: 'Montagscafe', description: 'Kaffee und so im Schauspielhaus',
        creator: user, orga: orga, date_start: 10.minutes.from_now)

      # starts in 1 day
      event2 = create(:event, title: 'Morgen', description: 'Morgen wirds geil',
        creator: user, orga: orga, date_start: 1.day.from_now)

      # started yesterday, no end date
      event3 = create(:event, title: 'Joggen im Garten', description: 'Gemeinsames Laufengehen im Grossen Garten',
        creator: user, orga: orga, date_start: 1.day.ago)

      # started 2 days ago, ends yesterday
      event4 = create(:event, title: 'Joggen im Garten vor einem Tag', description: 'Gemeinsames Laufengehen im Grossen Garten von gestern',
        creator: user, orga: orga, date_start: 2.days.ago, date_end: 1.day.ago)

      # started yesterday, ends today morning 00:00
      event5 = create(:event, title: 'Gestern bis heute früh', description: 'Absaufen und Durchhängen',
        creator: user, orga: orga, date_start: 1.day.ago, date_end: Time.now.in_time_zone(Time.zone).beginning_of_day)

      # started yesterday, ends tomorrow
      event6 = create(:event, title: 'Gestern bis morgen', description: 'Absaufen und Durchhängen voll durchmachen',
        creator: user, orga: orga, date_start: 1.day.ago, date_end: 1.day.from_now)

      get :index, params: { filter: { date: 'past' } }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size
      assert_equal event3.id.to_s, json['data'][0]['id']
      assert_equal event4.id.to_s, json['data'][1]['id']

      get :index, params: { filter: { date: 'upcoming' } }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 5, json['data'].size
      assert_equal event0.id.to_s, json['data'][0]['id']
      assert_equal event1.id.to_s, json['data'][1]['id']
      assert_equal event2.id.to_s, json['data'][2]['id']
      assert_equal event5.id.to_s, json['data'][3]['id']
      assert_equal event6.id.to_s, json['data'][4]['id']
    end

    should 'get events filtered for start and end of given orga' do
      user = create(:user)
      orga = create(:orga)

      # starts today morning 00:00
      event0 = create(:event, title: 'Hackathon', description: 'Mate fuer alle!',
        creator: user, host: orga, date_start: Time.now.in_time_zone(Time.zone).beginning_of_day)

      # starts in 10 minutes
      event1 = create(:event, title: 'Montagscafe', description: 'Kaffee und so im Schauspielhaus',
        creator: user, host: orga, date_start: 10.minutes.from_now)

      # starts in 1 day
      event2 = create(:event, title: 'Morgen', description: 'Morgen wirds geil',
        creator: user, host: orga, date_start: 1.day.from_now)

      # started yesterday, no end date
      event3 = create(:event, title: 'Joggen im Garten', description: 'Gemeinsames Laufengehen im Grossen Garten',
        creator: user, host: orga, date_start: 1.day.ago)

      # started 2 days ago, ends yesterday
      event4 = create(:event, title: 'Joggen im Garten vor einem Tag', description: 'Gemeinsames Laufengehen im Grossen Garten von gestern',
        creator: user, host: orga, date_start: 2.days.ago, date_end: 1.day.ago)

      # started yesterday, ends today morning 00:00
      event5 = create(:event, title: 'Gestern bis heute früh', description: 'Absaufen und Durchhängen',
        creator: user, host: orga, date_start: 1.day.ago, date_end: Time.now.in_time_zone(Time.zone).beginning_of_day)

      # started yesterday, ends tomorrow
      event6 = create(:event, title: 'Gestern bis morgen', description: 'Absaufen und Durchhängen voll durchmachen',
        creator: user, host: orga, date_start: 1.day.ago, date_end: 1.day.from_now)

      get :get_related_resources, params: { related_type: 'orga', id: orga.id, filter: { date: 'past' } }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size
      assert_equal event3.id.to_s, json['data'][0]['id']
      assert_equal event4.id.to_s, json['data'][1]['id']

      get :get_related_resources, params: { related_type: 'orga', id: orga.id, filter: { date: 'upcoming' } }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 5, json['data'].size
      assert_equal event0.id.to_s, json['data'][0]['id']
      assert_equal event1.id.to_s, json['data'][1]['id']
      assert_equal event2.id.to_s, json['data'][2]['id']
      assert_equal event5.id.to_s, json['data'][3]['id']
      assert_equal event6.id.to_s, json['data'][4]['id']
    end

    should 'ensure creator for event on create' do
      params = parse_json_file(file: 'create_event_without_orga.json') do |payload|
        payload.gsub!('<annotation_category_id_1>', AnnotationCategory.first.id.to_s)
        payload.gsub!('<annotation_category_id_2>', AnnotationCategory.second.id.to_s)
      end
      post :create, params: params
      assert_response :created, response.body
      assert @controller.current_api_v1_user, Event.last.creator
      json = JSON.parse(response.body)
      assert json['data']['relationships']['creator']
    end

    should 'ignore given creator for event' do
      params = parse_json_file(file: 'create_event_without_orga.json') do |payload|
        payload.gsub!('<annotation_category_id_1>', AnnotationCategory.first.id.to_s)
        payload.gsub!('<annotation_category_id_2>', AnnotationCategory.second.id.to_s)
      end
      params['data']['relationships'].merge!(
        'creator' => {
          data: {
            id: '123',
            type: 'users'
          }
        }
      )
      post :create, params: params
      assert_response :created, response.body
      assert_not_equal 123, Event.last.creator_id
      assert @controller.current_api_v1_user, Event.last.creator
      json = JSON.parse(response.body)
      assert json['data']['relationships']['creator']
    end

    context 'with given event' do
      setup do
        orga = create(:orga)
        @event = create(:event, host: orga)
      end

      should 'get show' do
        get :show, params: { id: @event.id }
        assert_response :ok, response.body
        json = JSON.parse(response.body)

        assert_kind_of Hash, json['data']
        assert_not json['data']['attributes']['has_time_start']
        assert_not json['data']['attributes']['has_time_end']
      end

      should 'get show event with time_start and time_end' do
        assert @event.update(time_start: true, time_end: true)
        get :show, params: { id: @event.id }
        assert_response :ok, response.body
        json = JSON.parse(response.body)
        assert_kind_of Hash, json['data']
        assert json['data']['attributes']['has_time_start']
        assert json['data']['attributes']['has_time_end']
      end

      should 'deliver hosts with different detail granularity' do
        get :index
        json = JSON.parse(response.body)['data'][0]
        assert_nil json['relationships']['hosts']

        get :index, params: { ids: [@event.id] }
        json = JSON.parse(response.body)['data'][0]
        assert_equal 1, json['relationships']['hosts']['data'][0]['attributes'].count
        assert_nil json['relationships']['hosts']['data'][0]['attributes']['count_upcoming_events']

        get :show, params: { id: @event.id }
        json = JSON.parse(response.body)['data']
        assert_operator 1, :<, json['relationships']['hosts']['data'][0]['attributes'].count
        assert_equal 1, json['relationships']['hosts']['data'][0]['attributes']['count_upcoming_events']

      end

      should 'deliver different attributes and relations when show or index' do
        get :index
        json = JSON.parse(response.body)['data'][0]

        attributes = [
          "title",
          "created_at",
          "updated_at",
          "date_start",
          "date_end",
          "has_time_start",
          "has_time_end",
          "active"
        ]

        relationships = ["facet_items", "navigation_items"]

        assert_same_elements attributes, json['attributes'].keys
        assert_same_elements relationships, json['relationships'].keys

        get :index, params: { ids: [@event.id] }
        json = JSON.parse(response.body)['data'][0]

        attributes = [
          "title",
          "created_at",
          "updated_at",
          "state_changed_at",
          "date_start",
          "date_end",
          "has_time_start",
          "has_time_end",
          "active"
        ]

        relationships = ["hosts", "annotations", "facet_items", "navigation_items", "creator", "last_editor"]

        assert_same_elements attributes, json['attributes'].keys
        assert_same_elements relationships, json['relationships'].keys

        get :show, params: { id: @event.id }
        json = JSON.parse(response.body)['data']

        attributes = [
          "title",
          "created_at",
          "updated_at",
          "state_changed_at",
          "date_start",
          "date_end",
          "has_time_start",
          "has_time_end",
          "active",
          "description",
          "short_description",
          "media_url",
          "media_type",
          "support_wanted",
          "support_wanted_detail",
          "tags",
          "certified_sfr",
          "public_speaker",
          "location_type",
          "legacy_entry_id",
          "facebook_id",
          'contact_spec'
        ]
        relationships = ["hosts", "annotations", "facet_items", "navigation_items", "creator", "last_editor", "contacts"]

        assert_same_elements attributes, json['attributes'].keys
        assert_same_elements relationships, json['relationships'].keys
      end
    end

    should 'I want to create a new event' do
      orga = create(:orga)
      params = parse_json_file(file: 'create_event_without_orga.json') do |payload|
        payload.gsub!('<annotation_category_id_1>', AnnotationCategory.first.id.to_s)
        payload.gsub!('<annotation_category_id_2>', AnnotationCategory.second.id.to_s)
      end
      params['data']['attributes'].merge!('active' => true)
      params['data']['relationships'].merge!(
        orga: {
          data: {
            type: 'orgas',
            id: orga.id
          }
        }
      )

      assert_difference 'Event.count' do
        post :create, params: params
        assert_response :created, response.body
      end
      json = JSON.parse(response.body)
      assert_equal StateMachine::INACTIVE.to_s, Event.last.state
      assert_equal false, json['data']['attributes']['active']

      user = Current.user
      assert_equal user.area, Event.last.area
      assert_equal user.id, Event.last.creator_id
      assert_equal user.id, Event.last.last_editor_id
    end

    should 'allow to create event with existing title' do
      event = create(:event, title: 'test')
      event2 = create(:event, title: 'test')

      assert_equal event.title, event2.title
    end

    should 'create event with host' do
      actor = create(:orga)
      actor2 = create(:orga_with_random_title)
      params = parse_json_file(file: 'create_event_without_orga.json')
      params['data']['relationships'].merge!(
        hosts: [actor.id, actor2.id]
      )

      assert_difference -> { EventHost.count }, 2 do
        assert_difference -> { Event.count } do
          post :create, params: params
          assert_response :created
        end
      end

      json = JSON.parse(response.body)
      event = Event.last
      event_json = JSON.parse(event.to_json)
      event_json = {'data' => event_json}
      assert_equal event_json, json
    end

    should 'create event with host and link contact of first host' do
      actor = create(:orga)
      assert actor.linked_contact
      assert actor.contacts.first
      actor2 = create(:orga)
      assert actor2.linked_contact
      assert actor2.contacts.first

      params = parse_json_file(file: 'create_event_without_orga.json')
      params['data']['relationships'].merge!(
        hosts: [actor.id, actor2.id]
      )

      assert_difference -> { EventHost.count }, 2 do
        assert_difference -> { Event.count } do
          post :create, params: params
          assert_response :created
        end
      end

      json = JSON.parse(response.body)
      event = Event.last
      event_json = JSON.parse(event.to_json)
      event_json = {'data' => event_json}
      assert_equal event_json, json

      assert_equal actor.linked_contact, event.linked_contact
      assert_equal actor.contacts.first, event.linked_contact
      assert_empty event.contacts
    end

    should 'An event should only change allowed states' do
      # allowed transition active -> inactive
      orga = create(:another_orga)
      event = create(:event, orga: orga)
      assert event.inactive?
      last_state_change = event.state_changed_at
      last_update = event.state_changed_at

      sleep 1

      process :update, methode: :patch, params: {
        id: event.id,
        data: {
          id: event.id,
          type: 'events',
          attributes: {
            active: true
          }
        }
      }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert event.reload.active?
      assert(
        last_state_change < DateTime.parse(json['data']['attributes']['state_changed_at']),
        "#{last_state_change} is not newer than #{json['data']['attributes']['state_changed_at']}")
      assert last_update < json['data']['attributes']['updated_at']
    end

    should 'ignore given state on event create' do
      assert_difference 'Event.count' do
        params = parse_json_file(file: 'create_event_without_orga.json') do |payload|
          payload.gsub!('<annotation_category_id_1>', AnnotationCategory.first.id.to_s)
          payload.gsub!('<annotation_category_id_2>', AnnotationCategory.second.id.to_s)
        end
        params['data']['attributes'].merge!('state' => StateMachine::ACTIVE.to_s)
        post :create, params: params
        assert_response :created, response.body
      end
      assert Event.last.inactive?
      json = JSON.parse(response.body)
      assert_equal false, json['data']['attributes']['active']
    end

    should 'set default orga on event create without orga relation' do
      params = parse_json_file(file: 'create_event_without_orga.json') do |payload|
        payload.gsub!(/"annotations":.*"locations":/m, '"locations":')
      end
      post :create, params: params
      assert_response :created, response.body
      assert_equal 'some title', Event.last.title
      assert_equal Orga.root_orga.id, Event.last.orga_id
    end

    should 'fail for invalid' do
      assert_no_difference 'Event.count' do
        assert_no_difference 'AnnotationCategory.count' do
          assert_no_difference 'ContactInfo.count' do
            assert_no_difference 'Location.count' do
              post :create, params: {
                data: {
                  type: 'events',
                  attributes: {
                    x: 'y'
                  },
                  relationships: {
                  },
                  test: {
                  }
                }
              }
              assert_response :unprocessable_entity
              json = JSON.parse(response.body)
              assert_equal(
                [
                  'Titel - fehlt',
                  'Kurzbeschreibung - fehlt',
                  'Start-Datum - fehlt'
                ],
                json['errors']
              )
            end
          end
        end
      end
    end

    should 'update event without sub_category' do
      event = create(:event, title: 'foobar', creator: nil)

      assert_no_difference 'Event.count' do
        assert_no_difference 'ContactInfo.count' do
          assert_no_difference 'Location.count' do
            patch :update,
              params: {
                id: event.id,
              }.merge(
                parse_json_file(
                  file: 'update_event_without_sub_category.json'
                ) do |payload|
                  payload.gsub!('<id>', event.id.to_s)
                end
              )
            assert_response :ok, response.body
          end
        end
      end
      event.reload
      assert_equal 'Street Store', event.title
      assert_equal Category.main_categories.first.id, event.category_id

      user = Current.user
      assert_equal user.area, Event.last.area
      assert_equal user.id, Event.last.creator_id
      assert_equal user.id, Event.last.last_editor_id
      json = JSON.parse(response.body)
      assert_equal user.id.to_s, json['data']['relationships']['creator']['data']['id']
      assert_equal user.id.to_s, json['data']['relationships']['last_editor']['data']['id']
    end

    should 'destroy event' do
      assert @event = create(:event)
      assert_difference 'Event.count', -1 do
        assert_difference 'Event.undeleted.count', -1 do
          assert_no_difference 'AnnotationCategory.count' do
            delete :destroy,
              params: {
                id: @event.id,
              }
            assert_response :no_content, response.body
          end
        end
      end
    end

    should 'update an event without creator and set the creator automatically' do
      assert event = create(:event)
      event.creator = nil
      assert event.save(validate: false)
      Annotation.create!(detail: 'annotation123', entry: event, annotation_category: AnnotationCategory.first)
      annotation = event.annotations.last

      assert_no_difference 'Event.count' do
        patch :update,
          params: {
            id: event.id,
          }.merge(
            parse_json_file(
              file: 'update_event_without_sub_category.json'
            ) do |payload|
              payload.gsub!('<id>', event.id.to_s)
              payload.gsub!('<annotation_id_1>', annotation.id.to_s)
            end
          )
        assert_response :ok, response.body
        assert @controller.current_api_v1_user, event.reload.creator
      end
    end

    should 'link hosts' do
      host = create(:orga)
      host2 = create(:orga_with_random_title)
      event = create(:event)

      assert_no_difference -> { Orga.count } do
        assert_difference -> { EventHost.count }, 2 do
          post :link_hosts, params: { id: event.id, actors: [host.id, host2.id] }
          assert_response :created, response.body
          assert response.body.blank?
        end
      end

      assert_equal event, host.events.first
      assert_equal event, host2.events.first
      assert_equal [host, host2], event.hosts

      assert_no_difference -> { Orga.count } do
        assert_difference -> { EventHost.count }, -1 do
          post :link_hosts, params: { id: event.id, actors: [host2.id] }
          assert_response :created, response.body
          assert response.body.blank?
        end
      end

      event.reload
      assert_equal [], host.events
      assert_equal event, host2.events.first
      assert_equal [host2], event.hosts

      assert_no_difference -> { Orga.count } do
        assert_difference -> { EventHost.count }, -1 do
          post :link_hosts, params: { id: event.id, actors: [] }
          assert_response :created, response.body
          assert response.body.blank?
        end
      end

      event.reload
      assert_equal [], host.events
      assert_equal [], host2.events
      assert_equal [], event.hosts
    end

    should 'throw error on linking nonexisting host' do
      host = create(:orga)
      event = create(:event)

      assert_no_difference -> { Orga.count } do
        assert_no_difference -> { EventHost.count } do
          post :link_hosts, params: { id: event.id, actors: [host.id, 2341] }
          assert_response :unprocessable_entity
          assert response.body.blank?
        end
      end
    end

    should 'throw error on linking host of different area' do
      host = create(:orga)
      host2 = create(:orga_with_random_title, area: 'xyzabc')
      event = create(:event)

      assert_no_difference -> { Orga.count } do
        assert_no_difference -> { EventHost.count } do
          post :link_hosts, params: { id: event.id, actors: [host.id, host2.id] }
          assert_response :unprocessable_entity
          assert response.body.blank?
        end
      end
    end

  end

end
