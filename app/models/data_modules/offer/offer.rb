module DataModules::Offer
  class Offer < ApplicationRecord
    include Jsonable
    include Translatable

    # ASSOCIATIONS
    has_many :offer_owners, class_name: DataModules::Offer::OfferOwner, dependent: :destroy
    has_many :owners, through: :offer_owners, source: :actor

    scope :by_area, ->(area) { where(area: area) }

    scope :all_for_ids, -> (ids, includes = default_includes) {
      includes(includes).
      where(id: ids)
    }

    after_commit on: [:create, :update] do
      fapi_client = FapiClient.new
      fapi_client.entry_updated(self)
    end

    after_destroy do
      fapi_client = FapiClient.new
      fapi_client.entry_deleted(self)
    end

    # CLASS METHODS
    class << self
      def translatable_attributes
        %i(title description)
      end

      def translation_key_type
        'offer'
      end

      def attribute_whitelist_for_json
        default_attributes_for_json
      end

      def lazy_attributes_for_json
        %i(title).freeze
      end

      def default_attributes_for_json
        (lazy_attributes_for_json + %i(description)).freeze
      end

      def relation_whitelist_for_json
        default_relations_for_json
      end

      def lazy_relations_for_json
        %i(facet_items navigation_items).freeze
      end

      def default_relations_for_json
        (lazy_relations_for_json + %i(owners facet_items navigation_items)).freeze
      end

      def lazy_includes
        [
          :facet_items,
          :navigation_items
        ]
      end

      def default_includes
        lazy_includes + [
          :owners
        ]
      end

      def offer_params(offer, params)
        permitted = [:title, :description, :actors]
        unless offer.id
          permitted << :area
        end
        params.permit(permitted)
      end

      def save_offer(params)
        offer = find_or_initialize_by(id: params[:id])
        offer.assign_attributes(offer_params(offer, params))
        offer.save!
        offer
      end
    end

    def link_owner(actor_id)
      owner = Orga.find(actor_id)
      unless owner.area == self.area
        raise 'Owner is in wrong area'
      end
      DataModules::Offer::OfferOwner.create(
        actor: owner,
        offer: self
      )
    end

    # TODO owners are part of the list resource as well as the item resource
    # but we want to include more owner details on the item resource
    # hence, there is a patch of this method in offer_controller#show
    def owners_to_hash
      owners.map { |o| o.to_hash(attributes: [:title], relationships: nil) }
    end

    include DataPlugins::Facet::Concerns::HasFacetItems
    include DataModules::FeNavigation::Concerns::HasFeNavigationItems
  end
end
