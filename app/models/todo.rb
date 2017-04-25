class Todo < ApplicationRecord

  self.table_name = 'annotation_able_relations'

  include Jsonable

  belongs_to :annotation
  belongs_to :entry, polymorphic: true

  scope :with_annotation, -> { joins(:annotation) }

  scope :with_entries,
    -> {
      joins("LEFT JOIN orgas ON orgas.id = annotation_able_relations.entry_id AND entry_type = 'Orga'").
        joins("LEFT JOIN events ON events.id = annotation_able_relations.entry_id AND entry_type = 'Event'")
    }

  scope :grouped_by_entries, -> { group(:entry_id, :entry_type) }

  # CLASS METHODS
  class << self
    def attribute_whitelist_for_json
      default_attributes_for_json
    end

    def default_attributes_for_json
      %i(messages).freeze
    end

    def relation_whitelist_for_json
      default_relations_for_json
    end

    def default_relations_for_json
      %i(entry).freeze
    end
  end

  def messages
    entry.todos.pluck(:detail)
  end

  def entry_to_hash
    entry.try(&:to_hash)
  end

end
