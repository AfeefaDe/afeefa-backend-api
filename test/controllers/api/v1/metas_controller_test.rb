require 'test_helper'

class Api::V1::MetasControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'I want to get all meta data' do
      assert orga = create(:orga, title: 'Gartenschmutz', description: 'hallihallo')

      # starts in 1 day
      event = create(:event, title: 'Morgen', description: 'Morgen wirds geil',
        orga: orga, date_start: 1.day.from_now)

      # started yesterday, no end date
      event2 = create(:event, title: 'Joggen im Garten', description: 'Gemeinsames Laufengehen im Grossen Garten',
        orga: orga, date_start: 1.day.ago)

      get :index
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Hash, json['meta']
      assert_equal Orga.count, json['meta']['orgas']

      assert_equal 2, Event.count
      assert_equal 2, json['meta']['events']['all']
      assert_equal 1, json['meta']['events']['past']
      assert_equal 1, json['meta']['events']['upcoming']

      assert_equal 0, json['meta']['todos']

      Annotation.create!(detail: 'ganz wichtig', entry: orga, annotation_category: AnnotationCategory.first)
      Annotation.create!(detail: 'ganz wichtig 2', entry: orga, annotation_category: AnnotationCategory.first)
      Annotation.create!(detail: 'ganz wichtig', entry: event, annotation_category: AnnotationCategory.first)

      get :index
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Hash, json['meta']
      assert_equal Orga.count, json['meta']['orgas']

      assert_equal 2, Event.count
      assert_equal 2, json['meta']['events']['all']
      assert_equal 1, json['meta']['events']['past']
      assert_equal 1, json['meta']['events']['upcoming']

      assert_equal Annotation.grouped_by_entries.count.count, json['meta']['todos']
    end
  end

end
