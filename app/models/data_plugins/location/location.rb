module DataPlugins::Location
  class Location < ApplicationRecord

    self.table_name = 'addresses'

    include Jsonable

    # SCOPES
    scope :selectable_in_area, -> (area) {
      includes(:owner).
      joins("INNER JOIN orgas on owner_type = 'Orga' and owner_id = orgas.id").
      where(owner_type: 'Orga', 'orgas.area': area)
    }

    # ASSOCIATIONS
    belongs_to :owner, polymorphic: true
    belongs_to :contact, class_name: ::DataPlugins::Contact::Contact
    has_many :linking_contacts, class_name: ::DataPlugins::Contact::Contact
    has_many :contacts, class_name: ::DataPlugins::Contact::Contact, dependent: :nullify

    geocoded_by :address_for_geocoding, latitude: :lat, longitude: :lon
    attr_accessor :address

    # VALIDATIONS
    validates :title, length: { maximum: 255 }
    validates :street, length: { maximum: 255 }
    validates :zip, length: { maximum: 255 }
    validates :city, length: { maximum: 255 }
    validates :lat, length: { maximum: 255 }
    validates :lon, length: { maximum: 255 }
    validates :directions, length: { maximum: 65000 }

    def address_for_geocoding
      return self.address if self.address.present?

      address = ''
      %w(street zip city country).each do |attribute|
        if (value = send(attribute)).present?
          address << ', '
          address << value
        end
      end
      address.gsub(/\A, /, '')
    end

    def owner_to_hash
      if owner
        owner.to_hash(attributes: [:title], relationships: nil)
      end
    end

    # CLASS METHODS
    class << self
      def attribute_whitelist_for_json
        default_attributes_for_json.freeze
      end

      def default_attributes_for_json
        %i(title lat lon street zip city directions contact_id).freeze
      end

      def relation_whitelist_for_json
        (default_relations_for_json + %i(owner)).freeze
      end

      def default_relations_for_json
        [].freeze
      end
    end

  end
end
