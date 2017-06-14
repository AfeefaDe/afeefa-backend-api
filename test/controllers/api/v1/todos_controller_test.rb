require 'test_helper'

class Api::V1::TodosControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
      @annotation_category = AnnotationCategory.first
    end

    should 'get filtered for title and description' do
      assert orga = create(:orga, title: 'Gartenschmutz', description: 'hallihallo')
      assert event = create(:event, title: 'GartenFOObar')

      get :index, params: { filter: { title: 'Garten', description: 'hallo' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 0, json['data'].size

      Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: @annotation_category)
      Annotation.create!(detail: 'ganz wichtig 2', entry: orga, annotation_category: @annotation_category)
      Annotation.create!(detail: 'ganz wichtig', entry: event, annotation_category: @annotation_category)

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

    should 'get filtered for annotation category' do
      annotation_category2 = AnnotationCategory.last
      assert_not_equal @annotation_category, annotation_category2

      assert orga = create(:orga, title: 'Gartenschmutz', description: 'hallihallo')
      assert event = create(:event, title: 'GartenFOObar')

      get :index, params: { filter: { title: 'Garten', description: 'hallo' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 0, json['data'].size

      Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: @annotation_category)
      Annotation.create!(detail: 'ganz wichtig 2', entry: orga, annotation_category: annotation_category2)
      Annotation.create!(detail: 'ganz wichtig', entry: event, annotation_category: @annotation_category)

      get :index, params: { filter: { annotation_category_id: annotation_category2.id } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 1, json['data'].size
    end

    should 'get todos default filter and sort' do
      assert orga = create(:another_orga)
      todo1 = Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: @annotation_category)

      assert event = create(:event)
      todo2 = Annotation.create!(detail: 'Mache ma!', entry: event, annotation_category: @annotation_category)

      get :index, params: { include: 'annotations', filter: { todo: '' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size

      orga_json =
        if json['data'].first['type'] == 'orgas'
          json['data'].first
        else
          json['data'].last
        end
      event_json =
        if json['data'].first['type'] == 'events'
          json['data'].first
        else
          json['data'].last
        end

      expected = event.to_hash.deep_stringify_keys
      assert_equal expected, event_json

      expected = orga.to_hash.deep_stringify_keys
      assert_equal expected, orga_json
    end

    should 'multiple sort todos' do
      assert orga = create(:another_orga, title: 'foo'*3)
      todo1 = Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: @annotation_category)
      sleep(1)
      assert event = create(:event, title: 'foo'*3)
      todo2 = Annotation.create!(detail: 'Mache ma!', entry: event, annotation_category: @annotation_category)

      get :index, params: { filter: { todo: '' }, sort: 'title,-state_changed_at,title' }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size

      orga_json =
        if json['data'].first['type'] == 'orgas'
          json['data'].first
        else
          json['data'].last
        end
      event_json =
        if json['data'].first['type'] == 'events'
          json['data'].first
        else
          json['data'].last
        end

      expected = event.to_hash.deep_stringify_keys
      assert_equal expected, event_json

      expected = orga.to_hash.deep_stringify_keys
      assert_equal expected, orga_json
    end

  end

end
