require 'test_helper'

class Api::V1::OrgasControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get index' do
      get :index
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Orga.count, json['data'].size
    end

    should 'get title filtered list for orgas' do
      count = Orga.where('title like ?', '%Dresden%').count

      get :index, params: { filter: { title: '%Dresden%' } }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal count, json['data'].size
    end

    should 'get sub orga relation' do
      count = Orga.root_orga.sub_orgas.count

      get :show_relationship, params: { orga_id: Orga.root_orga.id, relationship: 'sub_orgas' }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal count, json['data'].count

      Orga.create!(title: 'Afeefa12345', description: 'Eine Beschreibung für Afeefa', parent_orga: Orga.root_orga)

      get :show_relationship, params: { orga_id: Orga.root_orga.id, relationship: 'sub_orgas' }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal count + 1, json['data'].count
    end

    should 'get orgas related to todo' do
      count = Todo.new.orgas.count

      get :get_related_resources, params: { todo_id: 1, relationship: 'orgas', source: 'api/v1/todos' }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal count, json['data'].size

      assert create(:orga)

      get :get_related_resources, params: { todo_id: 1, relationship: 'orgas', source: 'api/v1/todos' }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal count + 1, json['data'].size
      assert_equal Orga::ROOT_ORGA_TITLE, json['data'].first['attributes']['title']
    end

    context 'with given orga' do
      setup do
        @orga = create(:orga)
      end

      should 'get show' do
        get :show, params: { id: @orga.id }
        assert_response :ok
        json = JSON.parse(response.body)
        assert_kind_of Hash, json['data']
      end

      should 'I want to activate my orga' do
        patch :update, params: {
            id: @orga.id,
            data: {
                type: 'orgas',
                attributes: {
                    title: 'foo' * 3,
                    active: true
                }
            }
        }
        assert_response :no_content, response.body
      end

      should 'I want to deactivate my orga' do
        patch :update, params: {
            id: @orga.id,
            data: {
                type: 'orgas',
                attributes: {
                    title: 'bar' * 3,
                    active: false
                }
            }
        }
        assert_response :no_content, response.body
      end

      should 'I want to create a new orga' do
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
                            id: @orga.id,
                            type: 'orgas'
                        }
                    }
                }
            }
        }
        assert_response :created, response.body
      end

      should 'An orga should only change allowed states' do

        # allowed transition active -> inactive
        active_orga = create(:active_orga)
        assert active_orga.active?

        last_state_change = active_orga.state_changed_at
        last_update = active_orga.state_changed_at

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

    end
  end

end
