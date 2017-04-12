class Entry < ApplicationRecord

  self.table_name = 'entries'

  include Jsonable

  belongs_to :entry, polymorphic: true

  scope :with_entries,
    -> {
      joins("LEFT JOIN orgas ON orgas.id = entries.entry_id AND entry_type = 'Orga'").
        joins("LEFT JOIN events ON events.id = entries.entry_id AND entry_type = 'Event'")
    }

  def to_hash(only_reference: false, details: false, with_relationships: false)
    default_hash.merge(
      relationships: {
        entry: {
          data: entry.try(:to_hash, only_reference: false, with_short_relationships: true)
        }
      }
    )
  end

end
