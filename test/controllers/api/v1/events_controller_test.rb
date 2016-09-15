require 'test_helper'

class Api::V1::EventsControllerTest < ActionController::TestCase

  context 'As Admin' do
    setup do
      @event = Event.first
      @admin = admin
      stub_current_user(user: @admin)

      @orga = @admin.orgas.first
      @user_json = {forename: 'Rudi', surname: 'Dutschke', email: 'bob@afeefa.de'}
    end

    should 'I want to get a list of all events' do
      get :index
      assert_response :ok
      expected = ActiveModelSerializers::SerializableResource.new(Event.all, {})
      assert_equal expected.to_json, response.body
    end


    should 'I want the details of one specifc event' do
      get :show, params: { id: @event.id }
      assert_response :ok
      expected = ActiveModelSerializers::SerializableResource.new(Event.find(@event.id), {})
      assert_equal expected.to_json, response.body
    end

    should 'I want to create an event for my orga' do
      Event::Operations::Create.any_instance.expects(:process).once
      post :create, params: {
          owner: @orga,
          data: {
              type: 'Event',
              attributes: {
                  title: 'some title',
                  description: 'some description'
              }
          }
      }
      assert_response :created
    end

    should 'I want to create an event for my orga, it\'s invalid' do
      post :create, params: {
          owner: @orga,
          data: {
              type: 'Event',
              attributes: {
                  description: 'some description'
              }
          }
      }
      assert_response :unprocessable_entity
    end
  end
end
