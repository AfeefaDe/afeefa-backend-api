require 'test_helper'

class LocationTest < ActiveSupport::TestCase

  should 'render json' do
    assert_equal({ type: 'locations', id: nil }.to_json, Location.new.to_json)
  end

  should 'validate attributes' do
    location = Location.new
    # TODO: validations
    # assert_not location.valid?
    # assert_match 'muss ausgefüllt werden', location.errors[:locatable].first
  end

  should 'build address' do
    location = build(:location_dresden)
    assert_equal 'Reißigerstr. 6, 01307, Dresden, Deutschland', location.address_for_geocoding
    coords = location.geocode
    assert_equal [51.0436, 13.76696], coords
    assert_equal coords.first.to_s, location.lat
    assert_equal coords.last.to_s, location.lon
  end

end
