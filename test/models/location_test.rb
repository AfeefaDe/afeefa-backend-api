require 'test_helper'

class LocationTest < ActiveSupport::TestCase

  should 'validate attributes' do
    location = Location.new
    # TODO: validations
    # assert_not location.valid?
    # assert_match 'muss ausgefüllt werden', location.errors[:locatable].first
  end

  should 'build address' do
    location = build(:location_dresden)
    assert_equal 'Geisingstr. 31, 1, 01309, Dresden, Deutschland', location.address_for_geocoding
    coords = location.geocode
    assert_equal [51.04049380000001, 13.781949], coords
    assert_equal coords.first.to_s, location.lat
    assert_equal coords.last.to_s, location.lon
  end

end
