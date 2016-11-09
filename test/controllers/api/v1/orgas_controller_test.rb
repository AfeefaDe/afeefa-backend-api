require 'test_helper'

class Api::V1::OrgasControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get index' do
      get :index
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Orga.count, json['data'].size
    end

    should 'get title filtered list for orgas' do
      count = Orga.where('title like ?', '%Dresden%').count

      get :index, params: { filter: { title: 'Dresden' } }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal count, json['data'].size
    end

    should 'get sub orga relation' do
      orga = create(:orga_with_sub_orga)
      count = orga.sub_orgas.count

      get :show_relationship, params: { orga_id: orga.id, relationship: 'sub_orgas' }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal count, json['data'].count

      Orga.create!(title: 'Afeefa12345', description: 'Eine Beschreibung für Afeefa', parent_orga: orga)

      get :show_relationship, params: { orga_id: orga.id, relationship: 'sub_orgas' }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal count + 1, json['data'].count
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
      end

      should 'I want to create a new orga' do
        post :create, params: {
            data: {
                type: 'orgas',
                attributes: {
                    title: 'some title',
                    description: 'some description',
                    state_transition: 'activate'
                },
                relationships: {
                    parent_orga: {
                        data: {
                            id: @orga.id,
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

      should 'An orga should only change allowed states' do
        # allowed transition active -> inactive
        active_orga = create(:active_orga)
        assert active_orga.active?
        last_state_change = active_orga.state_changed_at
        last_update = active_orga.state_changed_at

        sleep(1)

        process :update, methode: :patch, params: {
          id: active_orga.id,
          data: {
            id: active_orga.id,
            type: 'orgas',
            attributes: {
              state_transition: 'deactivate'
            }
          }
        }

        assert_response :ok, response.body

        json = JSON.parse(response.body)

        assert last_state_change < json['data']['attributes']['state_changed_at'], "#{last_state_change} is not newer than #{json['data']['attributes']['state_changed_at']}"
        assert last_update < json['data']['attributes']['updated_at']
        assert active_orga.reload.inactive?

      end

      should 'ignore given state on orga create' do
        post :create, params: {
          data: {
            type: 'orgas',
            attributes: {
              title: 'some title',
              description: 'some description',
              state: StateMachine::ACTIVE.to_s
            },
            relationships: {
              parent_orga: {
                data: {
                  id: @orga.id,
                  type: 'orgas'
                }
              }
            }
          }
        }
        assert_response :created, response.body
        assert_equal 'some title', Orga.last.title
        assert Orga.last.inactive?
        json = JSON.parse(response.body)
        assert_equal StateMachine::INACTIVE.to_s, json['data']['attributes']['state']
      end

      should 'set default orga on orga create without parent relation' do
        post :create, params: {
          data: {
            type: 'orgas',
            attributes: {
              title: 'some title',
              description: 'some description'
            }
          }
        }
        assert_response :created, response.body
        assert_equal 'some title', Orga.last.title
        assert_equal Orga.root_orga.id, Orga.last.parent_orga_id
      end

      should 'set default orga on orga create with parent relation with id nil' do
        skip 'jsonapi gem does not support this'
        post :create, params: {
          data: {
            type: 'orgas',
            attributes: {
              title: 'some title',
              description: 'some description'
            },
            relationships: {
              parent_orga: {
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
    end
  end

end
