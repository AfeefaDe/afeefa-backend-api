require 'test_helper'

class EventTest < ActiveSupport::TestCase

  should 'validate attributes' do
    event = Event.new
    assert_not event.valid?
    assert_match 'muss ausgefüllt werden', event.errors[:title].first
    assert_match 'muss ausgefüllt werden', event.errors[:description].first
    assert_match 'ist kein gültiger Wert', event.errors[:category].first
    assert_match 'muss ausgefüllt werden', event.errors[:date].first
  end

  should 'set initial state for event' do
    assert Event.new.inactive?
    assert_equal StateMachine::INACTIVE, Event.new.state.to_sym
  end

  context 'with new event' do
    setup do
      @user = create(:user)
      @orga = create(:orga)
      @event = build(:event, orga: @orga, creator: @user)
    end

    should 'create event' do
      assert_difference 'Event.count' do
        assert @event.save, @event.errors.full_messages
        assert_equal @user, @event.creator
        assert_nil @event.parent_event
        assert_empty @event.sub_events
      end
    end

    should 'have contact_informations' do
      event = build(:event, orga: @orga, creator: @user, contact_infos: [])
      assert event.contact_infos.blank?
      assert event.save
      assert contact_info = create(:contact_info, contactable: event), contact_info.errors
      assert_includes event.reload.contact_infos, contact_info
    end

    should 'have categories' do
      @event = build(:event, category: nil, orga: @orga)
      @event.category = Able::CATEGORIES.last
      assert @event.category.present?
    end
  end

end
