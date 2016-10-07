class UserSerializer < BaseSerializer

  attributes :email, :forename, :surname

  has_many :orgas do
    link :related, "/api/v1/users/#{object.id}/orgas"
    include_data false
  end

  link :self do
    "/api/v1/users/#{object.id}"
  end

end
