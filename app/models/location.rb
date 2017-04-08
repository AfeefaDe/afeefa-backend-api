class Location < ApplicationRecord

  include Jsonable

  # ATTRIBUTES AND ASSOCIATIONS
  belongs_to :locatable, polymorphic: true

  geocoded_by :address_for_geocoding, latitude: :lat, longitude: :lon
  attr_accessor :address

  def address_for_geocoding
    return self.address if self.address.present?

    address = ''
    %w(street number zip city country).each do |attribute|
      if (value = send(attribute)).present?
        address << ', '
        address << value
      end
    end
    address.gsub(/\A, /, '')
  end

end
