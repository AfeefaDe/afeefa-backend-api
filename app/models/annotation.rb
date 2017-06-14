class Annotation < ApplicationRecord

  include Jsonable

  belongs_to :annotation_category
  belongs_to :entry, polymorphic: true

  scope :with_annotation_category, -> { includes(:annotation_category) }

  scope :with_entries,
    -> {
      joins("LEFT JOIN orgas ON orgas.id = #{table_name}.entry_id AND entry_type = 'Orga'").
        joins("LEFT JOIN events ON events.id = #{table_name}.entry_id AND entry_type = 'Event'")
    }

  scope :grouped_by_entries, -> { group(:entry_id, :entry_type) }

  # CLASS METHODS
  class << self
    def attribute_whitelist_for_json
      default_attributes_for_json
    end

    def default_attributes_for_json
      %i(detail).freeze
    end

    def relation_whitelist_for_json
      default_relations_for_json
    end

    def default_relations_for_json
      %i(annotation_category entry).freeze
    end
  end

  def to_todos_hash
    entry.try(&:to_hash)
  end

end
