require 'test_helper'

class Event::IndexTest < ActiveSupport::TestCase

  context 'As admin' do
    setup do
      @event = event
    end

    should 'I want a list of all events' do
      op = Event::Index.present({})
      assert_equal Event.all, op.model
    end

    should 'I want a list of all events, paged' do
      op = Event::Index.present({page: {number: 2, size: 2}})
      assert_equal Event.page(2).per(2), op.model
    end
  end
end