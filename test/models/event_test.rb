require 'test_helper'

class EventTest < ActiveSupport::TestCase

  should 'create event' do
    assert_difference 'Event.count' do
      event = Event.new
      assert event.save, event.errors.full_messages
      assert_nil event.creator
      assert_nil event.parent_event
      assert_empty event.sub_events
    end
  end

  should 'have contact_informations' do
    event = Event.new
    assert event.contact_infos.blank?
    assert contact_info = ContactInfo.create(contactable: event)
    assert_includes event.reload.contact_infos, contact_info
  end

  should 'have categories' do
    event = Event.new
    assert event.categories.blank?
    assert category = Category.new(title: 'irgendeine komische Kategorie')
    category.events << event
    assert category.save
    assert_includes event.reload.categories.reload, category
  end

end
