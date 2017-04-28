require 'test_helper'

class Api::V1::AnnotationsControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'I want to get all annotations' do
      get :index
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal Annotation.count, json['data'].size
    end

    should 'I want to get a single annotation' do
      event = create(:event, title: 'foobar')
      Annotation.create!(detail: 'annotation123', entry: event, annotation_category: AnnotationCategory.first)

      get :show, params: { id: Annotation.first }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Hash, json['data']
      assert_equal Annotation.first.to_hash.deep_stringify_keys, json['data']
    end
  end

end
