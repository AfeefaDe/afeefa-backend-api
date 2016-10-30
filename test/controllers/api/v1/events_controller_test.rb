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
      event0 = create(:event, title: 'Hackathon',
                      description: 'Mate fuer alle!', creator: user)
      event1 = create(:event, title: 'Montagscafe',
                      description: 'Kaffee und so im Schauspielhaus',
                      creator: user)
      event2 = create(:event, title: 'Joggen im Garten',
                      description: 'Gemeinsames Laufengehen im Grossen Garten',
                      creator: user)

      get :index, params: { filter: { title: '%Garten%' } }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 1, json['data'].size
    end

    should 'get events related to todo' do
      count = Todo.new.events.count

      get :get_related_resources, params: { todo_id: 1, relationship: 'events', source: 'api/v1/todos' }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal count, json['data'].size

      assert create(:event)

      get :get_related_resources, params: { todo_id: 1, relationship: 'events', source: 'api/v1/todos' }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal count + 1, json['data'].size
      assert_equal Todo.new.events.first.title, json['data'].first['attributes']['title']
      assert_equal Todo.new.events.last.title, json['data'].last['attributes']['title']
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

      should 'I want to create a new event' do
        post :create, params: {
          data: {
            type: 'events',
            attributes: {
              title: 'some title',
              description: 'some description',
              state_transition: 'activate'
            },
            relationships: {
              orgas:
                {
                  data:
                    [
                      {
                        id: create(:orga).id,
                        type: 'orgas'
                      }
                    ]
                },
              creator: {
                data: {
                  id: @controller.current_api_v1_user.id,
                  type: 'users'
                }
              }
            }
          }
        }
        assert_response :created, response.body
        json = JSON.parse(response.body)
        assert_equal StateMachine::ACTIVE.to_s, json['data']['attributes']['state']
      end

      should 'An event should only change allowed states' do
        # allowed transition active -> inactive
        active_event = create(:active_event)
        assert active_event.active?
        last_state_change = active_event.state_changed_at
        last_update = active_event.state_changed_at

        sleep(1)

        process :update, methode: :patch, params: {
          id: active_event.id,
          data: {
            id: active_event.id,
            type: 'events',
            attributes: {
              state_transition: 'deactivate'
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
        post :create, params: {
          data: {
            type: 'events',
            attributes: {
              title: 'some title',
              description: 'some description',
              state: StateMachine::ACTIVE.to_s
            },
            relationships: {
              orgas:
                {
                  data:
                    [
                      {
                        id: create(:orga).id,
                        type: 'orgas'
                      }
                    ]
                },
              creator: {
                data: {
                  id: @controller.current_api_v1_user.id,
                  type: 'users'
                }
              }
            }
          }
        }
        assert_response :created, response.body
        assert @event.reload.inactive?
        json = JSON.parse(response.body)
        assert_equal StateMachine::INACTIVE.to_s, json['data']['attributes']['state']
      end
    end
  end

end
