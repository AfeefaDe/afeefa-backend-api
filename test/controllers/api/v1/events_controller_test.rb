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
      assert_equal Event.last.to_hash.deep_stringify_keys, json['data'].last

      assert !json['data'].last['attributes'].key?('support_wanted_detail')
      assert json['data'].last['attributes'].key?('inheritance')
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
      assert_equal event_from_db.to_hash.deep_stringify_keys, json['data'].last
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
        creator: user, orga: orga, date_start: Time.now.beginning_of_day)

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
        creator: user, orga: orga, date_start: 1.day.ago, date_end: Time.now.beginning_of_day)

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
        creator: user, orga: orga, date_start: Time.now.beginning_of_day)

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
        creator: user, orga: orga, date_start: 1.day.ago, date_end: Time.now.beginning_of_day)

      # started yesterday, ends tomorrow
      event6 = create(:event, title: 'Gestern bis morgen', description: 'Absaufen und Durchhängen voll durchmachen',
        creator: user, orga: orga, date_start: 1.day.ago, date_end: 1.day.from_now)

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
        payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
        payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
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
        payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
        payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
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
        @event = create(:event)
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
    end

    should 'I want to create a new event' do
      orga = create(:orga)
      params = parse_json_file(file: 'create_event_without_orga.json') do |payload|
        payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
        payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
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
        assert_no_difference 'AnnotationCategory.count' do
          assert_difference 'Annotation.count', 2 do
            post :create, params: params
            assert_response :created, response.body
          end
        end
      end
      json = JSON.parse(response.body)
      assert_equal StateMachine::ACTIVE.to_s, Event.last.state
      assert_equal true, json['data']['attributes']['active']
      assert_includes AnnotationCategory.first.entries.pluck(:entry_id), Event.last.id
      assert_includes AnnotationCategory.second.entries.pluck(:entry_id), Event.last.id

      # Then we could deliver the mapping there
      %w(annotations).each do |relation|
        assert json['data']['relationships'][relation]['data'].any?, "No element for relation #{relation} found."
        assert_equal relation, json['data']['relationships'][relation]['data'].first['type']
        assert_equal(
          Event.last.send(relation).first.id.to_s,
          json['data']['relationships'][relation]['data'].first['id'])
      end

      user = @controller.current_api_v1_user
      assert_equal user.area, Event.last.area
      assert_equal user.id, Event.last.creator_id
      assert_equal user.id, Event.last.last_editor_id
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
          payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
          payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
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
        payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
        payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
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
                  },
                  relationships: {
                  }
                }
              }
              assert_response :unprocessable_entity, response.body
              json = JSON.parse(response.body)
              assert_equal(
                [
                  'Titel - fehlt',
                  'Kurzbeschreibung - fehlt',
                  'Start-Datum - fehlt'
                ],
                json['errors'].map { |x| x['detail'] }
              )
            end
          end
        end
      end
    end

    should 'update event without sub_category' do
      creator = create(:user)
      event = create(:event, title: 'foobar', creator_id: creator.id)
      Annotation.create!(detail: 'annotation123', entry: event, annotation_category: AnnotationCategory.first)
      annotation = event.annotations.last

      assert_no_difference 'Event.count' do
        assert_no_difference 'ContactInfo.count' do
          assert_no_difference 'Location.count' do
            assert_no_difference 'AnnotationCategory.count' do
              patch :update,
                params: {
                  id: event.id,
                }.merge(
                  parse_json_file(
                    file: 'update_event_without_sub_category.json'
                  ) do |payload|
                    payload.gsub!('<id>', event.id.to_s)
                    payload.gsub!('<annotation_id_1>', annotation.id.to_s)
                    payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
                    # payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
                  end
                )
              assert_response :ok, response.body
            end
          end
        end
      end
      event.reload
      assert_equal 'Street Store', event.title
      assert_equal 1, event.annotations.count
      assert_equal annotation.reload, event.annotations.first
      assert_equal 'foo-bar', annotation.reload.detail
      assert_equal Category.main_categories.first.id, event.category_id

      user = @controller.current_api_v1_user
      assert_not_equal creator.id, user.id
      assert_equal user.area, Event.last.area
      assert_equal creator.id, Event.last.creator_id
      assert_equal user.id, Event.last.last_editor_id
      json = JSON.parse(response.body)
      assert_equal creator.id.to_s, json['data']['relationships']['creator']['data']['id']
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

    should 'not destroy event with associated sub_event' do
      assert @event = create(:event)
      assert event = create(:another_event, parent_id: @event.id, orga_id: @event.orga.id)
      assert_equal @event.id, event.parent_id
      assert @event.reload.sub_events.any?

      assert_no_difference 'Event.count' do
        assert_no_difference 'Event.undeleted.count' do
          assert_no_difference 'ContactInfo.count' do
            assert_no_difference 'Location.count' do
              assert_no_difference 'AnnotationCategory.count' do
                delete :destroy,
                  params: {
                    id: @event.id,
                  }
                assert_response :locked, response.body
                json = JSON.parse(response.body)
                assert_equal 'Unterevents müssen gelöscht werden', json['errors'].first['detail']
              end
            end
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
              payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
            end
          )
        assert_response :ok, response.body
        assert @controller.current_api_v1_user, event.reload.creator
      end
    end

    should 'create new event with parent relation and inheritance' do
      orga = create(:orga)

      params = parse_json_file file: 'create_event_with_orga.json' do |payload|
        payload.gsub!('<orga_id>', orga.id.to_s)
        payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
        payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
      end

      assert_not_nil params['data']['attributes']['inheritance']
      inh = params['data']['attributes']['inheritance']

      assert_difference 'Event.count' do
        post :create, params: params
        assert_response :created, response.body
      end

      response_json = JSON.parse(response.body)
      new_event_id = response_json['data']['id']

      assert_equal Event.find(new_event_id).orga, orga

      #todo: ticket #276 somehow in create methode parent_orga is set to 1 (ROOT_ORGA) so inheritance gets unset, but WHY!!! #secondsave
      assert_equal inh, response_json['data']['attributes']['inheritance']
      assert_not_nil response_json['data']['attributes']['inheritance']
    end
  end

end
