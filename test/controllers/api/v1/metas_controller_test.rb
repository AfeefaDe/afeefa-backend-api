require 'test_helper'

class Api::V1::MetasControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'I want to get all meta data' do
      assert orga = create(:orga, title: 'Gartenschmutz', description: 'hallihallo')
      assert event = create(:event, title: 'GartenFOObar')

      get :index
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Hash, json['meta']
      assert_equal Orga.count, json['meta']['orgas']
      assert_equal Event.count, json['meta']['events']
      assert_equal 0, json['meta']['todos']

      Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: AnnotationCategory.first)
      Annotation.create!(detail: 'ganz wichtig 2', entry: orga, annotation_category: AnnotationCategory.first)
      Annotation.create!(detail: 'ganz wichtig', entry: event, annotation_category: AnnotationCategory.first)

      get :index
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Hash, json['meta']
      assert_equal Orga.count, json['meta']['orgas']
      assert_equal Event.count, json['meta']['events']
      assert_equal Annotation.grouped_by_entries.count.count, json['meta']['todos']
    end
  end

end
