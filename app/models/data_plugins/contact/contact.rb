module DataPlugins::Contact
  class Contact < ApplicationRecord
    include Jsonable

    # ASSOCIATIONS
    belongs_to :owner, polymorphic: true
    has_many :contact_persons, class_name: ::DataPlugins::Contact::ContactPerson, dependent: :destroy
    belongs_to :location, class_name: ::DataPlugins::Location::Location
    has_many :linking_actors, class_name: Orga, foreign_key: :contact_id, dependent: :restrict_with_exception

    # VALIDATIONS
    validates :title, length: { maximum: 1000 }
    validates :web, length: { maximum: 1000 }
    validates :social_media, length: { maximum: 1000 }
    validates :spoken_languages, length: { maximum: 255 }
    validates :opening_hours, length: { maximum: 65000 }
    validates :location_spec, length: { maximum: 255 }

    # SCOPES
    scope :selectable_in_area, -> (area) {
      includes(:owner).
      joins("INNER JOIN orgas on owner_type = 'Orga' and owner_id = orgas.id").
      where(owner_type: 'Orga', 'orgas.area': area, 'orgas.state': 'active')
    }

    # HOOKS
    after_destroy :remove_links

    def remove_links
      # delete location if it's own location
      if location && location.contact_id == id
        location.destroy
      end
    end

    after_commit on: [:create, :update] do
      if owner
        fapi_client = FapiClient.new
        fapi_client.entry_updated(owner)
      end
    end

    after_destroy do
      if owner
        fapi_client = FapiClient.new
        fapi_client.entry_updated(owner)
      end
    end

    def owner_to_hash(attributes: nil, relationships: nil)
      owner.to_hash(attributes: [:title], relationships: nil)
    end

    def contact_persons_to_hash(attributes: nil, relationships: nil)
      contact_persons.map { |cp| cp.to_hash(attributes: cp.class.default_attributes_for_json) }
    end

    def location_to_hash(
      attributes: DataPlugins::Location::Location.default_attributes_for_json,
      relationships: DataPlugins::Location::Location.default_relations_for_json
      )
      if location
        location.to_hash(
          attributes: attributes,
          relationships: relationships
        )
      end
    end

    # CLASS METHODS
    class << self
      def attribute_whitelist_for_json
        default_attributes_for_json.freeze
      end

      def default_attributes_for_json
        %i(title social_media spoken_languages web opening_hours location_spec).freeze
      end

      def relation_whitelist_for_json
        default_relations_for_json.freeze
      end

      def default_relations_for_json
        %i(location contact_persons owner).freeze
      end
    end
  end
end
