class Api::V1::UserResource < Api::V1::BaseResource

  model_name 'User'

  attributes :email, :forename, :surname

  # has_many :orgas
end
