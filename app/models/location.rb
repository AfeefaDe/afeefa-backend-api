class Location < ApplicationRecord

  include Jsonable

  # ATTRIBUTES AND ASSOCIATIONS
  belongs_to :locatable, polymorphic: true

  geocoded_by :address_for_geocoding, latitude: :lat, longitude: :lon
  attr_accessor :address

  # VALIDATIONS
  # validations to prevent mysql errors
  validates :lat, length: { maximum: 255 }
  validates :lon, length: { maximum: 255 }
  validates :street, length: { maximum: 255 }
  validates :placename, length: { maximum: 255 }
  validates :zip, length: { maximum: 255 }
  validates :city, length: { maximum: 255 }
  validates :district, length: { maximum: 255 }
  validates :state, length: { maximum: 255 }
  validates :country, length: { maximum: 255 }

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
