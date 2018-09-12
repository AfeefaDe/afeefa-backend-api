class Entry < ApplicationRecord

  include Jsonable

  belongs_to :entry, polymorphic: true

  scope :with_entries,
    -> {
      joins("LEFT JOIN orgas ON orgas.id = #{table_name}.entry_id AND entry_type = 'Orga'").
        joins("LEFT JOIN events ON events.id = #{table_name}.entry_id AND entry_type = 'Event'")
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

  def entry_to_hash(attributes: nil, relationships: nil)
    entry.try(&:to_hash)
  end

end
