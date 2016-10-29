class Api::V1::LocationResource < Api::V1::BaseResource
  attributes :lat, :lon, :street, :number, :addition, :zip, :city, :district, :state, :country, :displayed, :created_at, :updated_at

  has_one :locateable, polymorphic: true
end
