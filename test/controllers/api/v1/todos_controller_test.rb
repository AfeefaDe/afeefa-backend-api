require 'test_helper'

class Api::V1::TodosControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
      @annotation_category = AnnotationCategory.first
    end

    should 'get index only data of area of user' do
      user = @controller.current_api_v1_user

      # useful sample data
      orga = create(:orga, area: user.area + ' is different', parent: nil)
      assert_not_equal orga.area, user.area
      Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: AnnotationCategory.first)
      orga.annotations.last
      orga.sub_orgas.create(attributes_for(:another_orga, parent_orga: orga, area: 'foo'))

      get :index
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 0, json['data'].size

      assert orga.update(area: user.area)

      get :index
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Orga.by_area(user.area).count, json['data'].size
      orga_from_db = Orga.by_area(user.area).last
      assert_equal orga_from_db.annotations.first.to_todos_hash.deep_stringify_keys, json['data'].last
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
      Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: @annotation_category)
      assert event = create(:event)
      Annotation.create!(detail: 'Mache ma!', entry: event, annotation_category: @annotation_category)

      get :index, params: { include: 'annotations', filter: { todo: '' } }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size

      todo1 = Annotation.find(json['data'].first['id'])
      todo2 = Annotation.find(json['data'].last['id'])
      expected = {
        data: [
          {
            type: 'todos', id: todo1.id.to_s,
            relationships: {
              annotation: { data: todo1.to_hash(relationships: nil) },
              annotation_category: { data: @annotation_category.to_hash }, entry: { data: todo1.entry.to_hash }
            }
          },
          {
            type: 'todos', id: todo2.id.to_s,
            relationships: {
              annotation: { data: todo2.to_hash(relationships: nil) },
              annotation_category: { data: @annotation_category.to_hash }, entry: { data: todo2.entry.to_hash }
            }
          }
        ]
      }
      assert_equal expected.deep_stringify_keys, json
    end

    should 'multiple sort todos' do
      assert orga = create(:another_orga, title: 'foo'*3)
      Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: @annotation_category)
      assert event = create(:event, title: 'foo'*3)
      Annotation.create!(detail: 'Mache ma!', entry: event, annotation_category: @annotation_category)

      get :index, params: { filter: { todo: '' }, sort: 'title,-state_changed_at,title' }
      json = JSON.parse(response.body)
      assert_response :ok
      assert_kind_of Array, json['data']
      assert_equal 2, json['data'].size

      todo1 = Annotation.find(json['data'].first['id'])
      todo2 = Annotation.find(json['data'].last['id'])
      expected = {
        data: [
          {
            type: 'todos', id: todo1.id.to_s,
            relationships: {
              annotation: { data: todo1.to_hash(relationships: nil) },
              annotation_category: { data: @annotation_category.to_hash }, entry: { data: todo1.entry.to_hash }
            }
          },
          {
            type: 'todos', id: todo2.id.to_s,
            relationships: {
              annotation: { data: todo2.to_hash(relationships: nil) },
              annotation_category: { data: @annotation_category.to_hash }, entry: { data: todo2.entry.to_hash }
            }
          }
        ]
      }
      assert_equal expected.deep_stringify_keys, json
    end

  end

end
