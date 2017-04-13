class Todo < ApplicationRecord

  self.table_name = 'annotation_able_relations'

  include JsonableEntry

  belongs_to :annotation
  belongs_to :entry, polymorphic: true

  scope :with_annotation,
    -> { joins(:annotation) }

  scope :with_entries,
    -> {
      joins("LEFT JOIN orgas ON orgas.id = annotation_able_relations.entry_id AND entry_type = 'Orga'").
        joins("LEFT JOIN events ON events.id = annotation_able_relations.entry_id AND entry_type = 'Event'")
    }

end
