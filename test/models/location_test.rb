require 'test_helper'

class LocationTest < ActiveSupport::TestCase

  should 'render json' do
    assert_equal(Location.attribute_whitelist_for_json.sort,
      JSON.parse(Location.new.to_json)['attributes'].symbolize_keys.keys.sort)
  end

  should 'validate attributes' do
    location = Location.new
    # TODO: validations
    # assert_not location.valid?
    # assert_match 'muss ausgefüllt werden', location.errors[:locatable].first
  end

  should 'build address' do
    VCR.use_cassette('location_test_build_address') do
      location = build(:location_dresden)
      assert_equal 'Reißigerstr. 6, 01307, Dresden, Deutschland', location.address_for_geocoding
      coords = location.geocode
      assert coords.present?
      assert_equal [51.0436, 13.76696], coords
      assert_equal coords.first.to_s, location.lat
      assert_equal coords.last.to_s, location.lon
    end
  end

end
