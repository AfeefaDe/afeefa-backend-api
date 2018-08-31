class Annotation < ApplicationRecord
  include Jsonable

  belongs_to :annotation_category
  belongs_to :entry, polymorphic: true

  scope :group_by_entry, -> { group(:entry_id, :entry_type) }

  scope :by_area, -> (area) {
    joins("LEFT JOIN events ON events.id = entry_id AND entry_type = 'Event'").
    joins("LEFT JOIN orgas ON orgas.id = entry_id AND entry_type = 'Orga'").
    joins("LEFT JOIN offers ON offers.id = entry_id AND entry_type = 'DataModules::Offer::Offer'").
    where('events.area = ? or orgas.area = ? or offers.area = ?', area, area, area)
  }

  # CLASS METHODS
  class << self
    def entries(annotations)
      event_ids = annotations.select { |a| a.entry_type == 'Event' }.pluck(:entry_id)
      events = Event.all_for_ids(event_ids, [:annotations])

      actor_ids = annotations.select { |a| a.entry_type == 'Orga' }.pluck(:entry_id)
      orgas = Orga.all_for_ids(actor_ids, [:annotations])

      offer_ids = annotations.select { |a| a.entry_type == 'DataModules::Offer::Offer' }.pluck(:entry_id)
      offers = DataModules::Offer::Offer.all_for_ids(offer_ids, [:annotations])

      annotations.map do |a|
        if a.entry_type == 'Event'
          events.select { |e| e.id == a.entry_id }.first
        elsif a.entry_type == 'Orga'
          orgas.select { |o| o.id == a.entry_id }.first
        elsif a.entry_type == 'DataModules::Offer::Offer'
          offers.select { |o| o.id == a.entry_id }.first
        end
      end
    end

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

end
