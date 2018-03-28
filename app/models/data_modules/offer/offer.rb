module DataModules::Offer
  class Offer < ApplicationRecord
    include Jsonable

    # ASSOCIATIONS
    has_many :offer_owners, class_name: DataModules::Offer::OfferOwner, dependent: :destroy
    has_many :actors, through: :offer_owners

    scope :by_area, -> (area) {
      includes(:actors).
      where(orgas: { area: area}) # orga is the backing table of :actors
    }

    attr_accessor :actor_id

    # VALIDATIONS
    validate :actor_is_present_on_create, on: :create

    # HOOKS
    after_create :associate_actor_on_create

    # CLASS METHODS
    class << self
      def attribute_whitelist_for_json
        default_attributes_for_json.freeze
      end

      def default_attributes_for_json
        %i(title description).freeze
      end

      def relation_whitelist_for_json
        default_relations_for_json.freeze
      end

      def default_relations_for_json
        %i(actors facet_items).freeze
      end

      def offer_params(params)
        params.permit(:title, :description, :actor_id)
      end

      def save_offer(params)
        offer = find_or_initialize_by(id: params[:id])
        offer.assign_attributes(offer_params(params))
        offer.save!
        offer
      end
    end

    def actor_is_present_on_create
      if actor_id.blank?
        errors.add(:actor_id, 'Kein Eigentümer des Angebots angegeben.')
      end
      unless Orga.exists?(actor_id)
        errors.add(:actor_id, 'Kein Eigentümer des Angebots angegeben.')
      end
    end

    def associate_actor_on_create
      DataModules::Offer::OfferOwner.create(
        actor_id: actor_id,
        offer: self
      )
    end

    def actors_to_hash
      actors.map { |a| a.to_hash(attributes: [:title], relationships: nil) }
    end

    include DataPlugins::Facet::Concerns::HasFacetItems
    include DataModules::FeNavigation::Concerns::HasFeNavigationItems
  end
end
