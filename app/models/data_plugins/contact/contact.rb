module DataPlugins::Contact
  class Contact < ApplicationRecord
    include Jsonable

    # ASSOCIATIONS
    belongs_to :owner, polymorphic: true
    has_many :contact_persons, class_name: ::DataPlugins::Contact::ContactPerson, dependent: :destroy
    belongs_to :location, class_name: ::DataPlugins::Location::Location

    # VALIDATIONS
    validates :title, length: { maximum: 1000 }
    validates :web, length: { maximum: 1000 }
    validates :social_media, length: { maximum: 1000 }
    validates :spoken_languages, length: { maximum: 255 }
    validates :opening_hours, length: { maximum: 65000 }

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
        fapi_client.entry_deleted(owner)
      end
    end

    def contact_persons_to_hash
      contact_persons.map { |cp| cp.to_hash(attributes: cp.class.default_attributes_for_json) }
    end

    def location_to_hash
      if location
        location.to_hash(attributes: location.class.default_attributes_for_json)
      end
    end

    # CLASS METHODS
    class << self
      def attribute_whitelist_for_json
        default_attributes_for_json.freeze
      end

      def default_attributes_for_json
        %i(title social_media spoken_languages web opening_hours).freeze
      end

      def relation_whitelist_for_json
        default_relations_for_json.freeze
      end

      def default_relations_for_json
        %i(location contact_persons).freeze
      end
    end
  end
end
