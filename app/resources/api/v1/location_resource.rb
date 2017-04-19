class Api::V1::LocationResource < Api::V1::BaseResource

  model_name 'Location'

  attributes :lat, :lon, :street, :placename, :zip, :city,
    :directions,
    :created_at, :updated_at
  attribute :__id__, delegate: :internal_id

  has_one :locatable, polymorphic: true

end
