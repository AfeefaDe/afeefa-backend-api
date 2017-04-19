require 'test_helper'

class Api::V1::GeocodingsControllerTest < ActionController::TestCase

  should 'get geocoding unauthorized' do
    # TODO: stub geocoding api
    get :index
    assert_response :unauthorized

    get :index, params: { foo: 'bar' }
    assert_response :unauthorized

    get :index, params: { token: 'abc' }
    assert_response :unauthorized

    get :index, params: { token: Settings.geocoding.api_token }
    assert_response :unprocessable_entity
    assert_equal 'geocoding failed', response.body

    address_string = build(:location_dresden).address_for_geocoding
    get :index, params: { token: Settings.geocoding.api_token, address: address_string }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_kind_of Hash, json
    assert_equal '51.04049380000001', json['latitude'].to_s
    assert_equal '13.781949', json['longitude'].to_s
  end

end
