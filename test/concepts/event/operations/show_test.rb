require 'test_helper'

class Event::Operations::ShowTest < ActiveSupport::TestCase

  context 'As admin' do
    setup do
      @event = event
    end

    should 'I want the details of one specific event' do
      op = Event::Operations::Show.present({id: @event.id})

      assert_equal @event.title, op.model.title
      assert_equal @event.description, op.model.description
    end
  end
end