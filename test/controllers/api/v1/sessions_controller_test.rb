require 'test_helper'

class Api::V1::SessionsControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  test 'handle unauthorized login' do
    @request.env['devise.mapping'] = Devise.mappings[:api_v1_user]

    post :create, params: { user: 'foo', password: 'bar' }
    assert_response :unauthorized, response.body
    assert response.headers.key?('Cache-Control')
    assert 'private, max-age=0, no-cache', response.headers['Cache-Control']

    expected = 
      {
        success: false, 
        errors: ['Ungültige Anmeldeinformationen. Bitte versuchen Sie es erneut.']
      }.to_json
    assert_equal expected, response.body
  end

end
