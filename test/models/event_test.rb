require 'test_helper'

class EventTest < ActiveSupport::TestCase

  should 'validate attributes' do
    event = Event.new
    assert event.locations.blank?
    assert_not event.valid?
    assert event.errors[:locations].blank?
    assert_match 'muss ausgefüllt werden', event.errors[:title].first
    assert_match 'muss ausgefüllt werden', event.errors[:description].first
    assert_match 'muss ausgefüllt werden', event.errors[:date].first
    event.description = '-' * 351
    assert_not event.valid?
    assert_match 'ist zu lang', event.errors[:description].first

    assert_match 'muss ausgefüllt werden', event.errors[:category].first
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
      assert_equal StateMachine::INACTIVE.to_s, @event.state
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
      @event = build(:event, category: nil, sub_category: nil, orga: @orga)
      @event.category.blank?
      @event.sub_category.blank?
      @event.category = category = create(:category)
      @event.sub_category = sub_category = create(:sub_category)
      assert @event.save
      assert_equal category, @event.reload.category
      assert_equal sub_category, @event.reload.sub_category
    end

    should 'soft delete event' do
      assert @event.save
      assert_not @event.reload.deleted?
      assert_no_difference 'Event.unscoped.count' do
        assert_difference 'Event.undeleted.count', -1 do
          @event.delete!
        end
      end
      assert @event.reload.deleted?
    end

    should 'not soft delete event with associated event' do
      assert @event.save
      assert event = create(:event, orga: @orga, title: 'foo bar', parent_id: @event.id)
      assert event.save
      assert_equal @event.id, event.parent_id
      assert @event.reload.sub_events.any?
      assert_not @event.reload.deleted?
      assert_no_difference 'Event.count' do
        assert_no_difference 'Event.undeleted.count' do
          assert_no_difference 'Orga.undeleted.count' do
            exception =
              assert_raise CustomDeleteRestrictionError do
                @event.destroy!
              end
            assert_equal 'Unterereignisse müssen gelöscht werden', exception.message
          end
        end
      end
      assert_not @event.reload.deleted?
    end

    should 'exclude deleted events from undeleted scope' do
      assert @event.save
      assert_not @event.deleted?
      assert_includes Event.all, @event
      assert @event.soft_destroy
      assert @event.deleted?
      assert_not_includes Event.undeleted, @event
    end
  end

end
