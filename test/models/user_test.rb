require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'should initialize available_areas by area of user' do
    user = User.new(area: 'foo')
    assert user.available_areas.blank?

    assert_equal true, user.initialize_available_areas_by_area!, user.errors.inspect
    assert_equal ['foo'], user.available_areas
    assert_equal ['foo'], user.reload.available_areas
    
    assert_equal false, user.initialize_available_areas_by_area!
    
    user.available_areas = nil
    assert_equal true, user.initialize_available_areas_by_area!
  end
  
  test 'validate area according to available_areas for user' do
    user = valid_user
    assert user.area.present?
    assert user.available_areas.present?
    assert user.available_areas.include?(user.area)

    user.area = user.area + '123'
    assert user.invalid?
    assert user.errors.keys.include?(:area)
  end

  test 'should know if area is available' do
    user = User.new(available_areas: ['a', 'b', 'c'])
    assert user.area_available?('a')
    assert !user.area_available?('z')
    user.available_areas = user.available_areas << 'z'
    assert user.area_available?('z')
  end
end
