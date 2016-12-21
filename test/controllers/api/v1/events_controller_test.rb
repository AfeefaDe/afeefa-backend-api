require 'test_helper'

class Api::V1::EventsControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get index' do
      get :index
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Event.count, json['data'].size
    end

    should 'get title filtered list for events' do
      user = create(:user)
      orga = create(:orga)
      event0 = create(:event, title: 'Hackathon',
        description: 'Mate fuer alle!', creator: user, orga: orga)
      event1 = create(:event, title: 'Montagscafe',
        description: 'Kaffee und so im Schauspielhaus',
        creator: user, orga: orga)
      event2 = create(:event, title: 'Joggen im Garten',
        description: 'Gemeinsames Laufengehen im Grossen Garten',
        creator: user, orga: orga)

      get :index, params: { filter: { title: 'Garten' } }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 1, json['data'].size
    end

    should 'ensure creator for event on create' do
      params = parse_json_file(file: 'create_event_without_orga.json') do |payload|
        payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
        payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
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
      end
    end

    should 'I want to create a new event' do
      params = parse_json_file(file: 'create_event_without_orga.json') do |payload|
        payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
        payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
      end
      params['data']['attributes'].
        merge!('active' => true)
      assert_difference 'Event.count' do
        post :create, params: params
        assert_response :created, response.body
      end
      json = JSON.parse(response.body)
      assert_equal StateMachine::ACTIVE.to_s, Event.last.state
      assert_equal true, json['data']['attributes']['active']
    end

    should 'An event should only change allowed states' do
      # allowed transition active -> inactive
      orga = create(:another_orga)
      active_event = create(:active_event, orga: orga)
      assert active_event.active?
      last_state_change = active_event.state_changed_at
      last_update = active_event.state_changed_at

      sleep 1

      process :update, methode: :patch, params: {
        id: active_event.id,
        data: {
          id: active_event.id,
          type: 'events',
          attributes: {
            active: false
          }
        }
      }

      assert_response :ok, response.body

      json = JSON.parse(response.body)

      assert(
        last_state_change < json['data']['attributes']['state_changed_at'],
        "#{last_state_change} is not newer than #{json['data']['attributes']['state_changed_at']}")
      assert last_update < json['data']['attributes']['updated_at']
      assert active_event.reload.inactive?
    end

    should 'ignore given state on event create' do
      assert_difference 'Event.count' do
        params = parse_json_file(file: 'create_event_without_orga.json') do |payload|
          payload.gsub!('<category_id>', Category.main_categories.first.id.to_s)
          payload.gsub!('<sub_category_id>', Category.sub_categories.first.id.to_s)
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
      end
      post :create, params: params
      assert_response :created, response.body
      assert_equal 'some title', Event.last.title
      assert_equal Orga.root_orga.id, Event.last.orga_id
    end

    should 'set default orga on event create with orga relation with id nil' do
      skip 'jsonapi gem does not support this'
      post :create, params: {
        data: {
          type: 'events',
          attributes: {
            title: 'some title',
            description: 'some description',
            date: I18n.l(Date.tomorrow),
            category: Category.main_categories.first,
          },
          relationships: {
            orga: {
              data: {
                id: nil,
                type: 'orgas'
              }
            }
          }
        }
      }
      assert_response :created, response.body
      assert_equal 'some title', Orga.last.title
      assert_equal Orga.root_orga.id, Orga.last.parent_orga_id
    end

    should 'fail for invalid' do
      assert_no_difference 'Event.count' do
        assert_no_difference 'Annotation.count' do
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
                  'Titel - muss ausgefüllt werden',
                  'Beschreibung - muss ausgefüllt werden',
                  'Kategorie - ist kein gültiger Wert',
                  'Datum - muss ausgefüllt werden'
                ],
                json['errors'].map { |x| x['detail'] }
              )
            end
          end
        end
      end
    end

    should 'update event without sub_category' do
      event = create(:event, title: 'foobar')
      event.annotations.create(title: 'annotation123')
      annotation = event.annotations.last

      assert_no_difference 'Event.count' do
        assert_no_difference 'ContactInfo.count' do
          assert_no_difference 'Location.count' do
            assert_no_difference 'Annotation.count' do
              post :update,
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
      assert_equal 'annotation123', annotation.reload.title
      assert_equal Category.main_categories.first.id, event.category_id
    end

    should 'soft destroy event' do
      # TODO: What should we do with associated objects?
      assert_not @event.reload.deleted?
      assert_no_difference 'Event.count' do
        assert_difference 'Event.undeleted.count', -1 do
          assert_no_difference 'ContactInfo.count' do
            assert_no_difference 'Location.count' do
              assert_no_difference 'Annotation.count' do
                delete :destroy,
                  params: {
                    id: @event.id,
                  }
                assert_response :no_content, response.body
              end
            end
          end
        end
      end
      assert @event.reload.deleted?
    end
  end

end
