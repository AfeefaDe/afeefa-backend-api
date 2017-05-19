require 'test_helper'

class EventTest < ActiveSupport::TestCase

  should 'render json' do
    event = create(:event)
    assert_jsonable_hash(event)
    assert_jsonable_hash(event, attributes: event.class.attribute_whitelist_for_json)
    assert_jsonable_hash(event,
      attributes: event.class.attribute_whitelist_for_json,
      relationships: event.class.relation_whitelist_for_json)
    assert_jsonable_hash(event, relationships: event.class.relation_whitelist_for_json)
  end

  should 'validate attributes' do
    event = Event.new
    assert event.locations.blank?
    assert_not event.valid?
    assert event.errors[:locations].blank?
    assert_match 'muss ausgefüllt werden', event.errors[:title].first
    assert_match 'muss ausgefüllt werden', event.errors[:short_description].first
    # FIXME: validate category
    # assert_match 'muss ausgefüllt werden', event.errors[:category].first

    event.short_description = '-' * 351
    assert_not event.valid?
    assert_match 'ist zu lang', event.errors[:short_description].first

    event.inheritance = [:foo]
    assert_not event.valid?
    assert_match 'ist nicht gültig', event.errors[:inheritance].first
    event.inheritance = [:short_description]
    event.valid?
    event.inheritance = [:short_description]
  end

  should 'auto strip name and description' do
    event = Event.new(date_start: Date.tomorrow)
    event.title = '   abc 123   '
    event.description = '   abc 123   '
    event.short_description = '   abc 123   '
    assert event.valid?, event.errors.messages
    assert_equal 'abc 123', event.title
    assert_equal 'abc 123', event.description
    assert_equal 'abc 123', event.short_description
  end

  should 'create translation on event create' do
    skip 'phraseapp deactivated' unless phraseapp_active?
    event = build(:event)
    assert_not event.translation.blank?
    assert event.translation(locale: 'en').blank?
    assert event.save
    expected = { title: 'an event', description: 'description of an event' }
    assert_equal expected, event.translation
    assert_equal expected, event.translation(locale: 'en')
  end

  should 'update translation on event update' do
    skip 'phraseapp deactivated' unless phraseapp_active?
    event = create(:event)
    expected = { title: 'an event', description: 'description of an event' }
    assert_equal expected, event.translation
    assert_equal expected, event.translation(locale: 'en')
    assert event.update(title: 'foo-bar')
    expected = { title: 'foo-bar', description: 'description of an event' }
    assert_equal expected, event.translation
    assert_equal expected, event.translation(locale: 'en')
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

    should 'create and destroy orga' do
      assert_difference 'Event.count' do
        assert_difference %q|Entry.where(entry_type: 'Event').count| do
          assert @event.save, @event.errors.full_messages
          assert_equal @user, @event.creator
          assert_nil @event.parent_event
          assert_empty @event.sub_events
        end
      end

      assert_difference 'Event.count', -1 do
        assert_difference %q|Entry.where(entry_type: 'Event').count|, -1 do
          @event.destroy
        end
      end
    end

    should 'validate parent_id' do
      @event.save!
      @event.parent_id = @event.id
      assert_not @event.valid?
      assert_equal ['Can not be the parent of itself!'],  @event.errors[:parent_id]
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
      assert_no_difference 'Event.count' do
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
            assert_equal 'Unterevents müssen gelöscht werden', exception.message
          end
        end
      end
      assert_not @event.reload.deleted?
    end
  end

end
