module DataModules::Offer
  class Offer < ApplicationRecord
    include Jsonable
    include Translatable
    include LazySerializable
    include HasCreatorAndEditor

    # ASSOCIATIONS
    has_many :offer_owners, class_name: DataModules::Offer::OfferOwner, dependent: :destroy
    has_many :owners, through: :offer_owners, source: :actor

    validates :title, presence: true, length: { maximum: 150 }
    validates :short_description, presence: true, length: { maximum: 350 }

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
        %i(title short_description)
      end

      def translation_key_type
        'offer'
      end

      def attribute_whitelist_for_json
        (default_attributes_for_json + %i(short_description description image_url contact_spec)).freeze
      end

      def lazy_attributes_for_json
        %i(title active created_at updated_at).freeze
      end

      def default_attributes_for_json
        lazy_attributes_for_json
      end

      def relation_whitelist_for_json
        (default_relations_for_json + %i(contacts).freeze)
      end

      def lazy_relations_for_json
        %i(facet_items navigation_items).freeze
      end

      def default_relations_for_json
        (lazy_relations_for_json + %i(owners annotations creator last_editor)).freeze
      end

      def lazy_includes
        [
          :facet_items,
          :navigation_items
        ]
      end

      def default_includes
        lazy_includes + [
          :owners,
          :creator,
          :last_editor
        ]
      end

      def offer_params(offer, params)
        permitted = [:title, :short_description, :description, :active, :image_url, :contact_spec]
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

    # LazySerializable
    def lazy_serializer
      OfferSerializer
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
      owner
    end

    # TODO owners are part of the offer list resource as well as the item resource
    # The list default is just to load the owner with its title,
    # but we want to include more owner details on the item resource.
    # hence, there is a patch of this method in offers_controller#show
    # which adds more details to the offer relation than defined here.
    def owners_to_hash
      owners.map { |o| o.to_hash(attributes: [:title], relationships: nil) }
    end

    include DataPlugins::Contact::Concerns::HasContacts
    include DataPlugins::Location::Concerns::HasLocations
    include DataPlugins::Annotation::Concerns::HasAnnotations
    include DataPlugins::Facet::Concerns::HasFacetItems
    include DataModules::FeNavigation::Concerns::HasFeNavigationItems
  end
end
