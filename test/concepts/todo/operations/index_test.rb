require 'test_helper'

class Todo::Operations::IndexTest < ActiveSupport::TestCase

  context 'As member' do

    setup do
      @member = member
      @orga = @member.orgas.first
    end

    should 'I want a list my todos' do
      another_event = Event.first

      @orga.events << Event.create(title: 'blubb')
      event = @orga.reload.events.last
      event.state = Thing::STATE_NEW
      event.save!

      resp, op = Todo::Operations::Index.present({})
      assert(resp)
      assert_includes resp.model[:events], event
      assert_not_includes resp.model[:events], another_event
    end
  end
end