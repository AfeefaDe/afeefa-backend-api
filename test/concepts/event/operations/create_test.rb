require 'test_helper'

class Event::Operations::CreateTest < ActiveSupport::TestCase

  context 'As admin' do
    setup do
      @admin = admin
      @orga = @admin.orgas.first
    end

    should 'I want to create a new event for my orga' do
      assert_difference('OwnerThingRelation.count') do
        assert_difference('@orga.events.count') do
          response, operation =
              Event::Operations::Create.run(
                  {
                      owner: @orga,
                      data: {
                          attributes: {
                              title: 'super-awesome event',
                              description: 'this event will be magnificent'
                          },
                          type: 'Event'
                      }
                  }
              )
          assert(response)
          assert_instance_of(Event, operation.model)
          assert_equal Event.find_by_title('super-awesome event'),
                       @orga.reload.events.last
          assert OwnerThingRelation.find_by(
              ownable: Event.find_by_title('super-awesome event'),
              thingable: @orga)
        end
      end
    end

    should 'I must not create an invalid event' do
      assert_no_difference('OwnerThingRelation.count') do
        assert_no_difference('@orga.events.count') do
          response, operation = Event::Operations::Create.run(
              {
                  owner: @orga,
                  data: {
                      attributes: {
                          description: 'this event will be magnificent'
                      },
                      type: 'Event'
                  }
              }
          )
          assert_not(response)
        end
      end
    end
  end

  context 'As user' do
    setup do
      @user = valid_user
    end

    should 'I want to create a new event' do
      assert_difference('@user.events.count') do
        response, operation = Event::Operations::Create.run(
            {
                owner: @user,
                data: {
                    attributes: {
                        title: 'super-awesome event',
                        description: 'this event will be magnificent'
                    },
                    type: 'Event'
                }
            }
        )
        assert(response)
        assert_instance_of(Event, operation.model)
        assert_equal Event.find_by_title('super-awesome event'), @user.reload.events.last
        assert OwnerThingRelation.find_by(
            ownable: Event.find_by_title('super-awesome event'),
            thingable: @user)
      end
    end
  end

end
