require 'test_helper'

class Api::V1::EntriesControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get index' do
      get :index
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 1, json['data'].size
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

    should 'get filter todos' do
      assert orga = create(:another_orga)
      orga.annotations.create!(title: 'ganz wichtig')
      assert event = create(:event)
      event.annotations.create!(title: 'Mache ma!')

      get :index, params: { filter: { todo: '' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size
      assert_equal orga.id, json['data'].first['id']
      assert_equal event.id, json['data'].last['id']
    end

  end

end
