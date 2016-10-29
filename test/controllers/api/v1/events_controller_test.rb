require 'test_helper'

class Api::V1::EventsControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get title filtered list for events' do
      admin = create(:admin)
      event0 = create(:event, title: 'Hackathon',
                      description: 'Mate fuer alle!', creator: admin)
      event1 = create(:event, title: 'Montagscafe',
                      description: 'Kaffee und so im Schauspielhaus',
                      creator: admin)
      event2 = create(:event, title: 'Joggen im Garten',
                      description: 'Gemeinsames Laufengehen im Grossen Garten',
                      creator: admin)

      get :index, params: { filter: {title: '%Garten%'} }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json['data']
      assert_equal 1, json['data'].size
    end
  end

end
