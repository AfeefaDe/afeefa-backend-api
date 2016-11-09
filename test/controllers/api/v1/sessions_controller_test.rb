require 'test_helper'

class Api::V1::SessionsControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  should 'has cross origin header for create' do
    @request.env['devise.mapping'] = Devise.mappings[:api_v1_user]

    post :create, params: { user: 'foo', password: 'bar' }
    assert_response :unauthorized, response.body
    assert response.headers.key?('Access-Control-Allow-Origin')
    assert '*', response.headers['Access-Control-Allow-Origin']

    expected =
      {
        errors: [
          'Ungültige Anmeldeinformationen. Bitte versuchen Sie es erneut.'
        ]
      }.to_json
    assert_equal expected, response.body
  end

end
