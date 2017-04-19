class Location < ApplicationRecord

  include Jsonable

  # ATTRIBUTES AND ASSOCIATIONS
  belongs_to :locatable, polymorphic: true

  geocoded_by :address_for_geocoding, latitude: :lat, longitude: :lon
  attr_accessor :address

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
