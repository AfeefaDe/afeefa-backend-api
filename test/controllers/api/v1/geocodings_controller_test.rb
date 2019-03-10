require 'test_helper'

class Api::V1::GeocodingsControllerTest < ActionController::TestCase
  test 'should get geocoding unauthorized' do
    VCR.use_cassette('geocoding_controller_test_get_geocoding_unauthorized') do
      get :index
      assert_response :unauthorized

      get :index, params: { foo: 'bar' }
      assert_response :unauthorized

      get :index, params: { token: 'abc' }
      assert_response :unauthorized

      skip 'TODO: Fix this api call tests!'
      # do not check tokens here
      @controller.class.any_instance.stubs(:ensure_token).returns(true)

      skip 'TODO: Fix this api call tests!'
      get :index, params: { token: Settings.geocoding.api_token }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Hash, json
      assert_equal '52.9301625', json['latitude'].to_s
      assert_equal '-1.17922709650968', json['longitude'].to_s
      assert_equal 'Unit 6', json['street'].to_s
      assert_equal 'City of Nottingham', json['city'].to_s

      address_string = build(:location_dresden).address_for_geocoding
      get :index, params: { token: Settings.geocoding.api_token, address: address_string }
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_kind_of Hash, json
      assert_equal '51.0446829', json['latitude'].to_s
      assert_equal '13.7679679', json['longitude'].to_s
      assert_equal 'Reißigerstraße 20', json['street'].to_s
      assert_equal 'Dresden', json['city'].to_s
      assert_equal 'Reißigerstraße 20, 01307 Dresden, Deutschland', json['full_address'].to_s
    end
  end

end
