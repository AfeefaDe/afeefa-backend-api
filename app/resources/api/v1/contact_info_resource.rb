class Api::V1::ContactInfoResource < Api::V1::BaseResource
  attributes :mail, :phone, :contact_person, :created_at, :updated_at

  has_one :contactable, polymorphic: true
end
