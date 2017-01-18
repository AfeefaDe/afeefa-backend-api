class Api::V1::LocationResource < Api::V1::BaseResource
  attributes :lat, :lon, :street, :number, :placename, :zip, :city, :created_at, :updated_at
  attribute :__id__, delegate: :internal_id

  has_one :locatable, polymorphic: true
end
