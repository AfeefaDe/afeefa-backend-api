require 'test_helper'

class StateMachineTest < ActiveSupport::TestCase

  should 'set initial state for event' do
    assert Event.new.inactive?
    assert_equal StateMachine::INACTIVE, Event.new.state.to_sym
  end

  should 'create event' do
    assert_difference 'Event.count' do
      user = create(:user)
      orga = create(:orga)
      event = build(:event, creator: user, orga: orga)
      assert event.save, event.errors.full_messages
      assert_equal user, event.creator
      assert_nil event.parent_event
      assert_empty event.sub_events
    end
  end

  should 'have contact_informations' do
    user = create(:user)
    orga = create(:orga)
    event = build(:event, creator: user, orga: orga, contact_infos: [])
    event.save
    assert event.contact_infos.blank?
    assert contact_info = create(:contact_info, contactable: event), contact_info.errors
    assert_includes event.reload.contact_infos, contact_info
  end

  should 'have categories' do
    user = create(:user)
    orga = create(:orga)
    event = build(:event, creator: user, orga: orga)
    event.category = Category.main_categories.first
    assert event.category.present?
  end

end
