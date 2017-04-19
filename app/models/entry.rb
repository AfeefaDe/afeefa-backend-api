class Entry < ApplicationRecord

  self.table_name = 'entries'

  include Jsonable

  belongs_to :entry, polymorphic: true

  scope :with_entries,
    -> {
      joins("LEFT JOIN orgas ON orgas.id = entries.entry_id AND entry_type = 'Orga'").
        joins("LEFT JOIN events ON events.id = entries.entry_id AND entry_type = 'Event'")
    }

  # CLASS METHODS
  class << self
    def relation_whitelist_for_json
      %i(entry)
    end

    def default_relations_for_json
      %i(entry)
    end
  end

  def entry_to_hash
    entry.try(&:to_hash)
  end

end
