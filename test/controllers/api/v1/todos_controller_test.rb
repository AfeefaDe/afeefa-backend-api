require 'test_helper'

class Api::V1::TodosControllerTest < ActionController::TestCase

  context 'As member' do

    setup do
      @member = member
      stub_current_user(user: @member)

      @orga = @member.orgas.first
    end

    should 'I want to see todos' do
      get :index
      assert_response :ok
    end

    should 'I want a list my todos' do
      skip 'implement'
      another_event = Event.where(state: Thing::STATE_ACTIVE).first

      @orga.events << Event.create(title: 'blubb')
      event = @orga.reload.events.last
      event.state = Thing::STATE_NEW
      event.save!

      get :index
      response.body
      #assert_includes response.body[''], event
      #assert_not_includes resp.model[:events], another_event
    end
  end
end
