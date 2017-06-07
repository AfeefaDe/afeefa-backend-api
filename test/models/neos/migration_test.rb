require 'test_helper'

module Neos
  class MigrationTest < ActiveSupport::TestCase

    setup do
      Neos::Migration.stubs(:puts).returns(nil)
    end

    should 'activate migrated entries' do
      assert_difference '::Orga.count' do
        Neos::Migration.migrate(limit: { orgas: 1, events: 1 })
      end
      assert ::Orga.last.active?
      assert ::Event.last.active?
    end

    should 'not annotate gone events' do
      event_relation = Neos::Event.order(:created).limit(1)
      event = event_relation.first
      assert Neos::Event.stubs(:where).returns(event_relation)

      assert_difference '::Event.count' do
        assert_no_difference '::Orga.count' do
          Neos::Migration.migrate(limit: { orgas: 0, events: 1 })
        end
      end
      new_event = ::Event.last
      assert_equal event.entry_id, new_event.legacy_entry_id
      assert new_event.active?
      assert new_event.in?(::Event.past)
      assert_equal 0, new_event.annotations.count
      assert_equal 0, Annotation.where(entry_id: new_event.id, entry_type: 'Event').count
    end

    should 'keep active status of entries' do
      orga = Neos::Orga.where(locale: :de).first
      assert orga.update(descriptionshort: '-' * 500)
      assert orga.update(published: true)

      assert_difference '::Orga.count' do
        Neos::Migration.migrate(limit: { orgas: 1, events: 1 })
      end
      assert ::Orga.last.active?
      assert ::Orga.last.annotations.where('detail like ?', 'Kurzbeschreibung ist zu lang%').any?
    end

    should 'not add annotation for missing short description' do
      orga = Neos::Orga.where(locale: :de).first
      assert orga.update(descriptionshort: nil)

      assert_difference '::Orga.count' do
        Neos::Migration.migrate(limit: { orgas: 1, events: 1 })
      end
      assert ::Orga.last.annotations.where(detail: 'Kurzbeschreibung muss ausgefüllt werden').blank?
    end

    should 'handle inheritance on setting attributes' do
      orga =
        Neos::Orga.
          where(locale: :de).
          where(name: [nil, ''], descriptionshort: [nil, '']).
          where.not(parent_entry_id: [nil, '']).
          detect do |orga|
            orga.parent.descriptionshort.present?
          end

      assert orga.name.blank?
      assert orga.descriptionshort.blank?
      assert orga.parent.descriptionshort.present?

      new_orga = Neos::Migration.send(:build_orga_from_neos_orga, orga)
      Neos::Migration.send(:create_entry_and_handle_validation, orga) do
        new_orga
      end

      assert_equal orga.parent.name.strip, new_orga.title
      assert new_orga.short_description.blank?
      assert_match 'short_description', new_orga.inheritance
    end

    should 'handle inheritance on setting contact attributes' do
      orga =
        Neos::Orga.
          where(locale: :de).
          where(web: [nil, '']).
          where.not(parent_entry_id: [nil, '']).
          detect do |orga|
            (orga.mail.present? || orga.phone.present? || orga.facebook.present? ||
              orga.spokenlanguages.present? || orga.speakerpublic.present?) &&
              orga.parent.web.present?
          end

      assert orga.web.blank?
      assert_not orga.parent.web.blank?

      new_orga = Neos::Migration.send(:build_orga_from_neos_orga, orga)
      Neos::Migration.send(:create_entry_and_handle_validation, orga) do
        new_orga
      end

      assert_equal orga.parent.web, new_orga.contact_infos.first.web
    end

    should 'not handle inheritance on setting location attributes' do
      orga =
        Neos::Orga.
          includes(:locations).references(:locations).
          where(locale: :de).
          where(ddfa_main_domain_model_location: { arrival: [nil, ''] }).
          where.not(parent_entry_id: [nil, '']).
          select do |orga|
            (location = orga.locations.first).present? &&
              (location.lat.present? ||
                location.lon.present? ||
                location.street.present? ||
                location.placename.present? ||
                location.zip.present? ||
                location.city.present?
              ) &&
              orga.parent.locations.any? &&
              orga.parent.locations.first.arrival.present?
          end.first

      assert orga.locations.first.arrival.blank?
      assert_not orga.parent.locations.first.arrival.blank?

      new_orga = Neos::Migration.send(:build_orga_from_neos_orga, orga)
      Neos::Migration.send(:create_entry_and_handle_validation, orga) do
        new_orga
      end

      assert new_orga.locations.first.directions.blank?
    end

    should 'handle multiple inheritance flags on setting attributes' do
      orga =
        Neos::Orga.
          where(locale: :de).
          where(
            speakerpublic: [nil, ''], mail: [nil, ''], phone: [nil, ''], web: [nil, ''],
            facebook: [nil, ''], spokenlanguages: [nil, ''], descriptionshort: [nil, '']).
          where.not(parent_entry_id: [nil, '']).
          detect { |orga| orga.parent.descriptionshort.present? }

      new_orga = Neos::Migration.send(:build_orga_from_neos_orga, orga)
      Neos::Migration.send(:create_entry_and_handle_validation, orga) do
        new_orga
      end

      assert_equal 'short_description|contact_infos', new_orga.inheritance
      assert new_orga.short_description.blank?
      assert new_orga.contact_infos.blank?
    end

  end
end
