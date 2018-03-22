class Annotation < ApplicationRecord

  include Jsonable

  belongs_to :annotation_category
  belongs_to :orga, foreign_key: 'entry_id', foreign_type: 'Orga'
  belongs_to :event, foreign_key: 'entry_id', foreign_type: 'Event'

  #scope :with_annotation_category, -> {joins(:annotation_category)}

  scope :with_entries,
    -> {
      joins("LEFT JOIN orgas ON orgas.id = #{table_name}.entry_id AND entry_type = 'Orga'").
        joins("LEFT JOIN events ON events.id = #{table_name}.entry_id AND entry_type = 'Event'")
    }

  scope :grouped_by_entries, -> { group(:entry_id, :entry_type) }

  scope :by_area,
    ->(area) {
      where(
        'orgas.area = ? AND events.area IS NULL OR orgas.area IS NULL AND events.area = ?',
        area, area)
    }

  # CLASS METHODS
  class << self
    def attribute_whitelist_for_json
      default_attributes_for_json
    end

    def default_attributes_for_json
      %i(detail annotation_category_id).freeze
    end

    def relation_whitelist_for_json
      default_relations_for_json
    end

    def default_relations_for_json
      [].freeze
    end
  end

  def annotation_to_hash
    self.to_hash(relationships: nil)
  end

  def to_todos_hash
    data = nil
    if event
      data = event.to_hash
    end
    if orga
      data = orga.to_hash
    end

    default_hash(type: 'todos').
      merge(relationships: {
        entry: { data: data },
      })
  end

end
