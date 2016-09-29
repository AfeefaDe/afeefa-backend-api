require 'test_helper'

class Api::V1::TodosControllerTest < ActionController::TestCase

  context 'As member' do

    setup do
      @member = member
      stub_current_user(user: @member)

      @orga = @member.orgas.first
    end

    should 'I want to see ToDos' do
      Todo::Operations::Index.any_instance.expects(:model).once
      get :index
      assert_response :ok
    end
  end
end