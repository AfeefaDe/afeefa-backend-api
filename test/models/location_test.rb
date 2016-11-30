require 'test_helper'

class LocationTest < ActiveSupport::TestCase

  should 'validate attributes' do
    location = Location.new
    assert_not location.valid?
    assert_match 'muss ausgefüllt werden', location.errors[:locatable].first
  end

end
