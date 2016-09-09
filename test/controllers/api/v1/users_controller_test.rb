require 'test_helper'

class Api::V1::UsersControllerTest < ActionController::TestCase
  context 'As member' do
    setup do
      @member = create(:member, orga: build(:orga))
      stub_current_user(user: @member)
    end

    should 'I want a list of all my orgas' do
      assert_routing 'api/v1/users/1/orgas', controller: 'api/v1/users', action: 'list_orgas', id: '1'
    end

    should 'I request a list of all orgas of a different user' do
      user = create(:user)
      get :list_orgas, id: user.id
      assert_response :forbidden
    end

    should 'render json api spec for orga list' do
      orga = @member.orgas.first

      get :list_orgas, id: @member.id
      assert_response :ok
      expected = ActiveModelSerializers::SerializableResource.new([orga], {}).to_json
      assert_equal expected, response.body
    end
  end

end
