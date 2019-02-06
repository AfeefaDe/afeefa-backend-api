require 'test_helper'

class Api::V1::UsersControllerTest < ActionController::TestCase
  setup do
    @user = valid_user
    stub_current_user(user: @user)
  end

  test 'should update user only if given area is available' do
    new_forename = @user.forename + '123'
    new_surname = @user.surname + '123'
    new_organization = @user.organization || '' + '123'
    new_password = @user.password + '123'
    new_area = @user.area + '123'
    params = { 
      forename: new_forename,
      surname: new_surname,
      organization: new_organization,
      password: new_password,
      area: new_area
     }
    
    patch :update, params: { id: @user.id, data: { attributes: params } }
    assert_response 422, response.body
    assert json = JSON.parse(response.body)
    assert_equal json['errors'].to_json, @user.errors.to_json
    
    @user.update!(available_areas: @user.available_areas << new_area)
    patch :update, params: { id: @user.id, data: { attributes: params } }
    assert_response 200
    assert json = JSON.parse(response.body)
    assert_equal json['data'].to_json, @user.to_json

    assert attributes = json['data']['attributes']
    @user.reload
    assert_equal new_forename, @user.forename
    assert_equal new_forename, attributes['forename']
    assert_equal new_surname, @user.surname
    assert_equal new_surname, attributes['surname']
    assert_equal new_organization, @user.organization
    assert_equal new_organization, attributes['organization']
    assert_equal new_password, @user.password
    assert !attributes.key?('password')
    assert_equal new_area, @user.area
    assert_equal new_area, attributes['area']
  end
end
