require 'test_helper'

class Api::V1::EntriesControllerTest < ActionController::TestCase

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
      assert_equal 1, json['data'].size
    end

    should 'multiple sort entries' do
      assert orga = create(:orga, title: 'foo'*3)
      sleep(1)
      assert event = create(:event, title: 'foo'*3)

      get :index, params: { filter: { todo: '' }, sort: 'title,-state_changed_at,title' }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal Entry.count, json['data'].size
      Entry.all.each_with_index do |entry, index|
        assert_equal 'entries', json['data'][index]['type']
        assert_equal entry.id.to_s, json['data'][index]['id']
        json_entry = json['data'][index]['relationships']['entry']['data']
        assert_equal entry.entry_type.downcase.pluralize, json_entry['type']
        assert_equal entry.entry_id.to_s, json_entry['id']
      end
    end

    should 'search by multiple keywords' do
      assert orga = create(:orga, title: 'Gartenschmutz', description: 'hallihallo')
      assert event = create(:event, title: 'GartenFOObar')

      get :index, params: { filter: { title: 'Garten schmutz' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 1, json['data'].size

      get :index, params: { filter: { title: 'Garten foo' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 1, json['data'].size

      get :index, params: { filter: { title: 'Garten Garten' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size
    end

    should 'search by any context' do
      assert orga = create(:orga, title: 'Gartenschmutz', description: 'hallihallo')
      assert location = create(:location, locatable: orga, placename: 'foo', street: 'Test123')
      assert event = create(:event, title: 'GartenFOObar', orga: orga)

      get :index, params: { filter: { any: 'foo' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size

      get :index, params: { filter: { any: 'Garten foo' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size

      get :index, params: { filter: { title: 'Garten Garten' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size
    end
  end

end
