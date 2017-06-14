require 'test_helper'

class Api::V1::FacebookEventsControllerTest < ActionController::TestCase

  should 'get facebook events' do
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
    json.each_with_index do |json_event, index|
      %w(name start_time link_to_event owner link_to_owner).each do |attr|
        assert json_event[attr], "There is no attribute #{attr} for event #{json_event}"
      end
      if index < json.size - 1
        assert_not_equal json_event['id'], json[index + 1]['id']
        event1_end = Time.zone.parse(json_event['end_time']).to_i rescue nil
        event2_end = Time.zone.parse(json[index + 1]['end_time']).to_i rescue nil
        event1_start = Time.zone.parse(json_event['start_time']).to_i rescue nil
        event2_start = Time.zone.parse(json[index + 1]['start_time']).to_i rescue nil
        if event1_end.present?
          assert_operator event1_end, :<=, event2_end
        else
          if event1_start.present?
            assert_operator event1_start, :<=, event2_start
          end
        end
      end
    end
  end

  should 'not have cross origin header on unauthorized request' do
    get :index
    assert_response :unauthorized
    assert_nil response.headers['Access-Control-Allow-Origin']
    assert_nil response.headers['Access-Control-Request-Method']
  end

  should 'not have cross origin header on authorized request' do
    get :index, params: { token: Settings.facebook.api_token_for_event_request }
    assert_response :ok
    # assert_equal 'https://afeefa.de', response.headers['Access-Control-Allow-Origin']
    # assert_equal '*', response.headers['Access-Control-Request-Method']
    assert_nil response.headers['Access-Control-Allow-Origin']
    assert_nil response.headers['Access-Control-Request-Method']
  end

end
