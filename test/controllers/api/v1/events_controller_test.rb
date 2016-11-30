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
      post :create, params: {
        data: {
          type: 'events',
          attributes: {
            title: 'some title',
            description: 'some description',
            date: I18n.l(Date.tomorrow),
            category: Able::CATEGORIES.first,
            state_transition: 'activate'
          },
          relationships: {
            orga:
              {
                data:
                  {
                    id: create(:another_orga).id,
                    type: 'orgas'
                  }
              }
          }
        }
      }
      assert_response :created, response.body
      assert @controller.current_api_v1_user, Event.last.creator
      json = JSON.parse(response.body)
      assert json['data']['relationships']['creator']
    end

    should 'ignore given creator for event' do
      post :create, params: {
        data: {
          type: 'events',
          attributes: {
            title: 'some title',
            description: 'some description',
            date: I18n.l(Date.tomorrow),
            category: Able::CATEGORIES.first,
            state_transition: 'activate'
          },
          relationships: {
            orga:
              {
                data:
                  {
                    id: create(:another_orga).id,
                    type: 'orgas'
                  }
              },
            creator: {
              data: {
                id: '123',
                type: 'users'
              }
            }
          }
        }
      }
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
      post :create, params: {
        data: {
          type: 'events',
          attributes: {
            title: 'some title',
            description: 'some description',
            date: I18n.l(Date.tomorrow),
            category: Able::CATEGORIES.first,
            state_transition: 'activate'
          },
          relationships: {
            orga:
              {
                data:
                  {
                    id: create(:another_orga).id,
                    type: 'orgas'
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
      orga = create(:another_orga)
      active_event = create(:active_event, orga: orga)
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
      assert_difference 'Event.count' do
        post :create, params: {
          data: {
            type: 'events',
            attributes: {
              title: 'some title',
              description: 'some description',
              date: I18n.l(Date.tomorrow),
              category: Able::CATEGORIES.first,
              state: StateMachine::ACTIVE.to_s
            },
            relationships: {
              orga:
                {
                  data:
                    {
                      id: create(:another_orga).id,
                      type: 'orgas'
                    }
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
      end
      assert Event.last.inactive?
      json = JSON.parse(response.body)
      assert_equal StateMachine::INACTIVE.to_s, json['data']['attributes']['state']
    end

    should 'set default orga on orga create without orga relation' do
      post :create, params: {
        data: {
          type: 'events',
          attributes: {
            title: 'some title',
            description: 'some description',
            date: I18n.l(Date.tomorrow),
            category: Able::CATEGORIES.first,
          }
        }
      }
      assert_response :created, response.body
      assert_equal 'some title', Event.last.title
      assert_equal Orga.root_orga.id, Event.last.orga_id
    end

    should 'set default orga on event create without orga relation' do
      post :create, params: {
        data: {
          type: 'events',
          attributes: {
            title: 'some title',
            description: 'some description',
            date: I18n.l(Date.tomorrow),
            category: Able::CATEGORIES.first,
          }
        }
      }
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
            category: Able::CATEGORIES.first,
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
      post :create, params: {
        data: {
          type: 'events',
          attributes: {
            title: 'some title',
            description: 'some description',
            category: Able::CATEGORIES.first,
          },
          relationships: {
            orga:
              {
                data:
                  {
                    id: create(:another_orga).id,
                    type: 'orgas'
                  }
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
      assert_response :unprocessable_entity, response.body
      json = JSON.parse(response.body)
      assert_equal 'Datum - muss ausgefüllt werden', json['errors'].first['detail']
    end
  end

end
