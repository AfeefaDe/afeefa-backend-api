class UserSerializer < BaseSerializer

  attribute 'email'
  attribute 'forename'
  attribute 'surname'

  has_many :orgas do
    link :related, "/api/v1/users/#{object.id}/orgas"
    include_data false
  end

  link :self do
    "/api/v1/users/#{object.id}"
  end

end
