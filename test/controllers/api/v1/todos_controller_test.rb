require 'test_helper'

class Api::V1::TodosControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get filter title and description' do
      assert orga = create(:orga, title: 'Gartenschmutz', description: 'hallihallo')
      assert event = create(:event, title: 'GartenFOObar')

      get :index, params: { filter: { title: 'Garten', description: 'hallo' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 0, json['data'].size

      Todo.create!(detail: 'ganz wichtig', entry: orga, annotation: Annotation.first)
      Todo.create!(detail: 'ganz wichtig 2', entry: orga, annotation: Annotation.first)
      Todo.create!(detail: 'ganz wichtig', entry: event, annotation: Annotation.first)

      get :index, params: { filter: { title: 'Garten' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size

      get :index, params: { filter: { title: 'Garten', description: 'hallo' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 1, json['data'].size
    end

    should 'get todos default filter and sort' do
      assert orga = create(:another_orga)
      todo1 = Todo.create!(detail: 'ganz wichtig', entry: orga, annotation: Annotation.first)
      sleep(1)
      assert event = create(:event)
      todo2 = Todo.create!(detail: 'Mache ma!', entry: event, annotation: Annotation.first)

      get :index, params: { include: 'annotations', filter: { todo: '' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size

      expected = {
        data: [
          {
            type: 'todos', id: todo2.id.to_s,
            attributes:  { messages: ['Mache ma!'] },
            relationships: { entry: { data: event.to_hash } }
          },
          {
            type: 'todos', id: todo1.id.to_s,
            attributes: { messages: ['ganz wichtig'] },
            relationships: { entry: { data: orga.to_hash } }
          }
        ]
      }
      assert_equal expected.deep_stringify_keys, json    end

    should 'multiple sort todos' do
      assert orga = create(:another_orga, title: 'foo'*3)
      todo1 = Todo.create!(detail: 'ganz wichtig', entry: orga, annotation: Annotation.first)
      sleep(1)
      assert event = create(:event, title: 'foo'*3)
      todo2 = Todo.create!(detail: 'Mache ma!', entry: event, annotation: Annotation.first)

      get :index, params: { filter: { todo: '' }, sort: 'title,-state_changed_at,title' }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size

      expected = {
        data: [
          {
            type: 'todos', id: todo2.id.to_s,
            attributes:  { messages: ['Mache ma!'] },
            relationships: { entry: { data: event.to_hash } }
          },
          {
            type: 'todos', id: todo1.id.to_s,
            attributes: { messages: ['ganz wichtig'] },
            relationships: { entry: { data: orga.to_hash } }
          }
        ]
      }
      assert_equal expected.deep_stringify_keys, json
    end

  end

end
