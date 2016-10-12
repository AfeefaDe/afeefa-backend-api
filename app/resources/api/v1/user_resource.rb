class Api::V1::UserResource < Api::V1::BaseResource
  attributes :email, :forename, :surname

  has_many :orgas
end
