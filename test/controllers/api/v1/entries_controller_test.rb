require 'test_helper'

class Api::V1::EntriesControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get index' do
      get :index, params: { include: 'annotations,category,sub_category' }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      # root orga should not be shown
    end

    should 'get filter title and description' do
      assert orga = create(:orga, title: 'Gartenschmutz', description: 'hallihallo')
      assert event = create(:event, title: 'GartenFOObar')

      get :index, params: { filter: { title: 'Garten', description: 'hallo' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 1, json['data'].size
    end

    should 'get todos default filter and sort' do
      # skip 'this test will fail because we do not have a entries model and so the preload_included_fragments fails ' +
      #   'in base resource for calling arel_table on self._model_class which is nil because ' +
      #   'the resource in the api is abstract'

      # this test will fail if caching is enabled

      assert orga = create(:another_orga)
      orga.annotations.create!(title: 'ganz wichtig')
      sleep(1)
      assert event = create(:event)
      event.annotations.create!(title: 'Mache ma!')

      get :index, params: { include: 'annotations', filter: { todo: '' } }
      json = JSON.parse(response.body)
      assert_response :ok, json
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size
      assert_equal orga.id.to_s, json['data'].first['id']
      assert_equal 'orgas', json['data'].first['type']
      assert_equal event.id.to_s, json['data'].last['id']
      assert_equal 'events', json['data'].last['type']
    end

    should 'multiple sort todos' do
      assert orga = create(:another_orga, title: 'foo'*3)
      orga.annotations.create!(title: 'ganz wichtig')
      sleep(1)
      assert event = create(:event, title: 'foo'*3)
      event.annotations.create!(title: 'Mache ma!')

      get :index, params: { filter: { todo: '' }, sort: 'title,-state_changed_at,title' }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size
      assert_equal event.id.to_s, json['data'].first['id']
      assert_equal 'events', json['data'].first['type']
      assert_equal orga.id.to_s, json['data'].last['id']
      assert_equal 'orgas', json['data'].last['type']
    end

  end

end
