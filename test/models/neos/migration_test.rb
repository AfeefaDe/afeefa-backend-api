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

  end
end
