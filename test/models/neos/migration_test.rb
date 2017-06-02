require 'test_helper'

module Neos
  class MigrationTest < ActiveSupport::TestCase

    should 'activate migrated entries' do
      assert_difference '::Orga.count' do
        Neos::Migration.migrate(limit: { orgas: 1, events: 1 })
      end
      assert ::Orga.last.active?
      assert ::Event.last.active?
    end

    should 'activate migrated entries' do
      orga = Neos::Orga.where(locale: :de).first
      assert orga.update(descriptionshort: nil)

      assert_difference '::Orga.count' do
        Neos::Migration.migrate(limit: { orgas: 1, events: 1 })
      end
      assert ::Orga.last.annotations.where(detail: 'Kurzbeschreibung muss ausgefüllt werden').any?
    end

    should 'handle inheritance on setting attributes' do
      orga =
        Neos::Orga.
          where(locale: :de).
          where(name: [nil, ''], descriptionshort: [nil, '']).
          first

      assert orga.name.blank?
      assert orga.descriptionshort.blank?
      assert orga.locations.first.street.blank?

      new_orga = Neos::Migration.send(:build_orga_from_neos_orga, orga)
      Neos::Migration.send(:create_entry_and_handle_validation, orga) do
        new_orga
      end

      assert_equal orga.parent.name.strip, new_orga.title
      assert new_orga.short_description.blank?
      assert_equal 'short_description', new_orga.inheritance
    end

    should 'handle inheritance on setting contact attributes' do
      orga =
        Neos::Orga.
          where(locale: :de).
          where(web: [nil, '']).
          where.not(parent_entry_id: [nil, '']).
          first

      assert orga.web.blank?
      assert_not orga.parent.web.blank?

      new_orga = Neos::Migration.send(:build_orga_from_neos_orga, orga)
      Neos::Migration.send(:create_entry_and_handle_validation, orga) do
        new_orga
      end

      assert_equal orga.parent.web, new_orga.contact_infos.first.web
    end

    should 'handle multiple inheritance flags on setting attributes' do
      orga =
        Neos::Orga.
          where(locale: :de).
          where(speakerpublic: [nil, ''], mail: [nil, ''], phone: [nil, ''], web: [nil, ''], facebook: [nil, ''], spokenlanguages: [nil, ''], descriptionshort: [nil, '']).
          where.not(parent_entry_id: [nil, '']).
          first

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
