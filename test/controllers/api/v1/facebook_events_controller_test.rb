require 'test_helper'

class Api::V1::FacebookEventsControllerTest < ActionController::TestCase

    should 'get facebook events unauthorized' do
      # TODO: stub facebook api
      get :index
      assert_response :unauthorized

      get :index, params: { foo: 'bar' }
      assert_response :unauthorized

      get :index, params: { token: 'abc' }
      assert_response :unauthorized

      get :index, params: { token: Settings.facebook.api_token_for_event_request }
      assert_response :ok
      json = JSON.parse(response.body)
      assert_kind_of Array, json
      if json.blank?
        skip 'there are no events so we can not test the content of the events'
      end
      json.each do |json_event|
        %w(name description start_time link_to_event owner link_to_owner).each do |attr|
          assert json_event[attr], "There is no attribute #{attr} for event #{json_event}"
        end
      end
    end

end
