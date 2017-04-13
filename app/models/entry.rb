class Entry < ApplicationRecord

  self.table_name = 'entries'

  include JsonableEntry

  belongs_to :entry, polymorphic: true

  scope :with_entries,
    -> {
      joins("LEFT JOIN orgas ON orgas.id = entries.entry_id AND entry_type = 'Orga'").
        joins("LEFT JOIN events ON events.id = entries.entry_id AND entry_type = 'Event'")
    }

  private

  def relationships_for_json
    {
      category: { data: category.try(:to_hash) },
      sub_category: { data: sub_category.try(:to_hash) }
    }
  end

  def short_relationships_for_json
    relationships_for_json
  end

end
