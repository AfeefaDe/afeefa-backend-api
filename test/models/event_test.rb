require 'test_helper'

class EventTest < ActiveSupport::TestCase

  should 'set initial state for event' do
    assert Event.new.inactive?
    assert_equal StateMachine::INACTIVE, Event.new.state.to_sym
  end

  should 'create event' do
    assert_difference 'Event.count' do
      user = valid_user
      event = Event.new(creator: user)
      assert event.save, event.errors.full_messages
      assert_equal user, event.creator
      assert_nil event.parent_event
      assert_empty event.sub_events
    end
  end

  should 'have contact_informations' do
    event = Event.new(creator: valid_user)
    assert event.contact_info.blank?
    assert contact_info = ContactInfo.create(contactable: event), contact_info.errors
    assert_equal event.reload.contact_info, contact_info
  end

  should 'have categories' do
    event = Event.new(creator: valid_user)
    assert event.category.blank?
    event.category = 'irgendeine komische Kategorie'
    assert event.category.present?
  end

end
