module DataPlugins::Location
  class Location < ApplicationRecord

    self.table_name = 'addresses'

    include Jsonable

    # ASSOCIATIONS
    belongs_to :owner, polymorphic: true
    has_one :contact, class_name: ::DataPlugins::Contact::Contact

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

    # CLASS METHODS
    class << self
      def attribute_whitelist_for_json
        default_attributes_for_json.freeze
      end

      def default_attributes_for_json
        %i(lat lon street placename zip city directions displayed).freeze
      end

      def relation_whitelist_for_json
        default_relations_for_json.freeze
      end

      def default_relations_for_json
        %i(locatable).freeze
      end
    end

  end
end
