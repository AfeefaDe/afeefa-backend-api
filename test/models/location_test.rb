require 'test_helper'

class LocationTest < ActiveSupport::TestCase

  test 'should belongs_to orga' do
    loc = Location.new
    assert_nil loc.locatable

    orga = Orga.first
    loc.locatable = orga
    assert_equal orga.id, loc.locatable_id
    assert_equal 'Orga', loc.locatable_type
  end

end
