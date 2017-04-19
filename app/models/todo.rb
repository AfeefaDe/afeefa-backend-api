class Todo < ApplicationRecord

  self.table_name = 'annotation_able_relations'

  include Jsonable

  belongs_to :annotation
  belongs_to :entry, polymorphic: true

  scope :with_annotation,
    -> { joins(:annotation) }

  scope :with_entries,
    -> {
      joins("LEFT JOIN orgas ON orgas.id = annotation_able_relations.entry_id AND entry_type = 'Orga'").
        joins("LEFT JOIN events ON events.id = annotation_able_relations.entry_id AND entry_type = 'Event'")
    }

  def to_hash(only_reference: false, with_relationships: false)
    default_hash.merge(
      attributes: {
        messages: entry.todos.pluck(:detail)
      },
      relationships: {
        entry: {
          data: entry.try(:to_hash, with_short_relationships: true)
        }
      }
    )
  end

end
