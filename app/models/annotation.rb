class Annotation < ApplicationRecord
  include Jsonable

  belongs_to :annotation_category
  belongs_to :entry, polymorphic: true
  belongs_to :last_editor, class_name: 'User', optional: true
  belongs_to :creator, class_name: 'User', optional: true

  scope :group_by_entry, -> { group(:entry_id, :entry_type) }

  scope :by_area, -> (area) {
    joins("LEFT JOIN events ON events.id = entry_id AND entry_type = 'Event'").
    joins("LEFT JOIN orgas ON orgas.id = entry_id AND entry_type = 'Orga'").
    joins("LEFT JOIN offers ON offers.id = entry_id AND entry_type = 'DataModules::Offer::Offer'").
    where('events.area = ? or orgas.area = ? or offers.area = ?', area, area, area)
  }

  #VALIDATIONS
  validate :validate_consistency

  # HOOKS
  before_create do
    self.creator = Current.user
  end

  before_save do
    self.last_editor = Current.user
  end

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
      %i(detail annotation_category_id created_at updated_at).freeze
    end

    def relation_whitelist_for_json
      default_relations_for_json
    end

    def default_relations_for_json
      [:creator, :last_editor].freeze
    end

    def annotation_params(annotation, params)
      permitted = [:detail, :annotation_category_id, :entry_id, :entry_type]
      params.permit(permitted)
    end

    def save_annotation(params)
      annotation = params[:id] ? find(params[:id]) : Annotation.new
      annotation.assign_attributes(annotation_params(annotation, params))
      annotation.save!
      annotation
    end
  end

  def validate_consistency
    if persisted? && (changes.key?('entry_id') || changes.key?('entry_type'))
      return errors.add(:entry, 'Eigentümer kann nicht geändert werden.')
    end

    unless persisted?
      unless changes.key?('annotation_category_id')
        return errors.add(:annotation_category_id, 'Kategorie fehlt.')
      end

      unless entry
        return errors.add(:navigation_id, 'Entry existiert nicht.')
      end
    end

    if changes.key?('annotation_category_id')
      unless AnnotationCategory.exists?(annotation_category_id)
        return errors.add(:annotation_category_id, 'Kategorie existiert nicht.')
      end
    end
  end

  def annotation_to_hash
    self.to_hash(relationships: nil)
  end

  def last_editor_to_hash
    last_editor.try(&:to_hash)
  end

  def creator_to_hash
    creator.try(&:to_hash)
  end

end
