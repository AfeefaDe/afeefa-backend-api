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
    assert_includes event.to_json, '"upcoming":true'
    assert_not_includes event.to_json, '"past":'
  end

  should 'validate attributes' do
    orga = create(:orga)
    event = Event.new(orga: orga)
    assert event.locations.blank?
    assert_not event.valid?
    assert event.errors[:locations].blank?
    assert_match 'fehlt', event.errors[:title].first
    assert_match 'fehlt', event.errors[:short_description].first
    # FIXME: validate category
    # assert_match 'fehlt', event.errors[:category].first

    event.tags = 'foo bar'
    assert_not event.valid?
    assert_match 'ist nicht gültig', event.errors[:tags].first
    event.tags = 'foo,bar'
    event.valid?
    assert event.errors[:tags].blank?

    event.short_description = '-' * 351
    assert_not event.valid?
    assert_match 'ist zu lang', event.errors[:short_description].first

    event.inheritance = [:foo]
    assert_not event.valid?
    assert_match 'ist nicht gültig', event.errors[:inheritance].first
    event.inheritance = [:short_description]
    event.valid?
    assert_match 'ist nicht gültig', event.errors[:inheritance].first
    event.inheritance = 'short_description'
    event.valid?
    assert event.errors[:inheritance].blank?
  end

  should 'skip all validations' do
    event = Event.new
    event.skip_all_validations!
    assert event.valid?
    assert event.save
  end

  should 'have no validation on deactivate' do
    event = create(:event)
    assert event.activate!
    event.title = nil
    event.short_description = nil
    assert_not event.valid?
    assert event.deactivate!, event.errors.messages
    assert event.inactive?
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

    PhraseAppClient.any_instance.expects(:push_locale_file).with do |file, phraseapp_locale_id, tags_hash|
      event_id = Event.last.id.to_s

      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['event']
      assert_not_nil json['event'][event_id]
      assert_equal 'an event', json['event'][event_id]['title']
      assert_equal 'short description', json['event'][event_id]['short_description']

      assert_equal 'd4f1ed77b0efb45b7ebfeaff7675eeba', phraseapp_locale_id
      assert_equal 'dresden', tags_hash[:tags]
    end

    assert event.save
  end

  should 'update translation on event update' do
    skip 'phraseapp deactivated' unless phraseapp_active?

    event = create(:event)
    event_id = event.id.to_s

    PhraseAppClient.any_instance.expects(:push_locale_file).with do |file, phraseapp_locale_id, tags_hash|
      file = File.read(file)
      json = JSON.parse(file)

      assert_not_nil json['event']
      assert_not_nil json['event'][event_id]
      assert_equal 'foo-bar', json['event'][event_id]['title']
      assert_equal 'short-fo-ba', json['event'][event_id]['short_description']

      assert_equal 'd4f1ed77b0efb45b7ebfeaff7675eeba', phraseapp_locale_id
      assert_equal 'dresden', tags_hash[:tags]
    end

    assert event.update(title: 'foo-bar', short_description: 'short-fo-ba')
  end

  should 'update translation on event update only once' do
    skip 'phraseapp deactivated' unless phraseapp_active?

    event = create(:event)

    PhraseAppClient.any_instance.expects(:push_locale_file).once.with do |file, phraseapp_locale_id, tags_hash|
      assert true
    end

    assert event.update(title: 'foo-bar', short_description: 'short-fo-ba')
    assert event.update(title: 'foo-bar', short_description: 'short-fo-ba')
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

    should 'set inheritance to null if no parent orga given' do
      orga = create(:orga, title: 'hohoho', parent_orga_id: nil)
      event = create(:event, orga_id: orga.id, inheritance: 'short_description' )

      assert_equal orga.id, event.orga.id
      assert_equal 'short_description', event.inheritance

      event.orga = nil
      event.save

      assert_equal Orga.root_orga.id, event.reload.orga_id
      assert_equal nil, event.inheritance
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
      @event.sub_category = sub_category = create(:sub_category, parent_id: category.id)
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
