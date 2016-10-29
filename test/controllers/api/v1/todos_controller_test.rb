require 'test_helper'

class Api::V1::TodosControllerTest < ActionController::TestCase

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

    should 'get show' do
      get :show, params: { id: 1 }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Hash, json['data']
    end

    should 'get orga relation' do
      get :show_relationship, params: { todo_id: 1, relationship: 'orgas' }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      # We are creating 10 Orgas in seeds
      assert_equal 10, json['data'].size

      orga0 = Orga.new(title: 'Oberoberorga', description: 'Nothing goes above')
      orga0.save(validate: false)

      get :show_relationship, params: { todo_id: 1, relationship: 'orgas' }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      # We are having 11 Orgas in seeds
      assert_equal 11, json['data'].size
      # only the relation, no attributes
      assert_not json['data'].first.has_key?('attributes')
    end

  end

end
