require 'test_helper'

class Api::V1::UsersControllerTest < ActionController::TestCase

  context 'As user' do
    setup do
      @user = User.first
      stub_current_user(user: @user)
    end

    should 'I want to show my user' do
      get :show, params: { id: @user.id }
      assert_response :success
      expected =
        {
          data: {
            id: '1',
            type: 'users',
            attributes: {
              email: 'rudi@afeefa.de',
              forename: 'Rudi',
              surname: 'Dutschke'
            },
            relationships: {
              orgas: {
                links: {
                  related: '/api/v1/users/1/orgas'
                }
              }
            },
            links: {
              self:'/api/v1/users/1'
            }
          }
        }
      assert_equal expected.to_json, response.body
    end

  end
end
